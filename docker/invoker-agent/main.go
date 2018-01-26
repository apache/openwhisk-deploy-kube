/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

/* JSON structure expected as request body on /logs route */
type LogForwardInfo struct {
	LastOffset             int64  `json:"lastOffset"`
	SizeLimit              int    `json:"sizeLimit"`
	SentinelledLogs        bool   `json:"sentinelledLogs"`
	EncodedLogLineMetadata string `json:"encodedLogLineMetadata"`
	EncodedActivation      string `json:"encodedActivation"`
}

/* Size threshold for individual output files written by the logWriter */

/* String constants related to logging */
const (
	logSentinelLine        = "XXX_THE_END_OF_A_WHISK_ACTIVATION_XXX"
	truncatedLogMessage    = "Logs were truncated because the total bytes size exceeds the limit of %d bytes."
	genericLogErrorMessage = "There was an issue while collecting your logs. Data might be missing."
)

/* Should we measure and report time taken for each operation? */
const timeOps = false

/* configuration variables; may be overridden by setting matching envvar */
var (
	dockerSock       string = "/var/run/docker.sock"
	containerDir     string = "/containers"
	outputLogDir     string = "/action-logs"
	invokerAgentPort int    = 3233
	logSinkSize      int64  = 100 * 1024 * 1024
)

/* http.Client instance bound to dockerSock */
var client *http.Client

/* channel to send log lines to the logWriter */
var logSinkChannel chan string

/*
 * Support for writing log lines to the logSink
 */

// go routine that accepts log lines from the logSinkChannel and writes them to the logSink
func logWriter() {
	var sinkFile *os.File = nil
	var sinkFileBytes int64 = 0
	var err error

	for {
		line := <-logSinkChannel

		if sinkFile == nil {
			timestamp := time.Now().UnixNano() / 1000000
			fname := fmt.Sprintf("%s/userlogs-%d.log", outputLogDir, timestamp)
			sinkFile, err = os.Create(fname)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Unable to create log sink: %v\n", err)
				panic(err)
			}
			sinkFileBytes = 0
		}

		bytesWritten, err := fmt.Fprintln(sinkFile, line)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error writing to log sink: %v\n", err)
			panic(err)
		}

		sinkFileBytes += int64(bytesWritten)
		if sinkFileBytes > logSinkSize {
			sinkFile.Close()
			sinkFile = nil
		}
	}
}

func writeSyntheticLogLine(msg string, metadata string) {
	now := time.Now().UTC().Format(time.RFC3339)
	line := fmt.Sprintf("{\"log\":\"%s\", \"stream\":\"stderr\", \"time\":\"%s\",%s}", msg, now, metadata)
	logSinkChannel <- line
}

func reportLoggingError(w http.ResponseWriter, code int, msg string, metadata string) {
	w.WriteHeader(code)
	fmt.Fprint(w, msg)
	fmt.Fprintln(os.Stderr, msg)
	if metadata != "" {
		writeSyntheticLogLine(genericLogErrorMessage, metadata)
	}
}

// Request handler for /logs route
func forwardLogsFromUserAction(w http.ResponseWriter, r *http.Request) {
	var start time.Time
	if timeOps {
		start = time.Now()
	}

	vars := mux.Vars(r)
	container := vars["container"]

	var lfi LogForwardInfo
	b, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		reportLoggingError(w, 400, fmt.Sprintf("Error reading request body: %v", err), "")
		return
	}
	err = json.Unmarshal(b, &lfi)
	if err != nil {
		reportLoggingError(w, 400, fmt.Sprint("Error unmarshalling request body: %v", err), "")
		return
	}

	logFileName := containerDir + "/" + container + "/" + container + "-json.log"
	logFile, err := os.Open(logFileName)
	defer logFile.Close()
	if err != nil {
		reportLoggingError(w, 500, fmt.Sprintf("Error opening %s: %v", logFileName, err), lfi.EncodedLogLineMetadata)
		logSinkChannel <- lfi.EncodedActivation // Write activation record before returning with error code.
		return
	}

	offset, err := logFile.Seek(lfi.LastOffset, 0)
	if offset != lfi.LastOffset || err != nil {
		reportLoggingError(w, 500, fmt.Sprintf("Unable to seek to %d in log file", lfi.LastOffset), lfi.EncodedLogLineMetadata)
		logSinkChannel <- lfi.EncodedActivation // Write activation record before returning with error code.
		return
	}

	sentinelsLeft := 2
	scanner := bufio.NewScanner(logFile)
	bytesWritten := 0
	for sentinelsLeft > 0 && scanner.Scan() {
		logLine := scanner.Text()
		if lfi.SentinelledLogs && strings.Contains(logLine, logSentinelLine) {
			sentinelsLeft -= 1
		} else {
			logLineLen := len(logLine)
			bytesWritten += logLineLen
			mungedLine := fmt.Sprintf("%s,%s}", logLine[:logLineLen-1], lfi.EncodedLogLineMetadata)
			logSinkChannel <- mungedLine
			if bytesWritten > lfi.SizeLimit {
				writeSyntheticLogLine(fmt.Sprintf(truncatedLogMessage, lfi.SizeLimit), lfi.EncodedLogLineMetadata)
				logFile.Seek(0, 2) // Seek to end of logfile to skip rest of output and prepare for next action invoke
				sentinelsLeft = 0  // Cause loop to exit now.
			}
		}
	}

	if lfi.SentinelledLogs && sentinelsLeft != 0 {
		reportLoggingError(w, 500, "Failed to find expected sentinels in log file", lfi.EncodedLogLineMetadata)
		logSinkChannel <- lfi.EncodedActivation // Write activation record before returning with error code.
		return
	}

	// Done copying log; write the activation record.
	logSinkChannel <- lfi.EncodedActivation

	// seek 0 bytes from current position to set logFileOffset to current fpos
	logFileOffset, err := logFile.Seek(0, 1)
	if err != nil {
		reportLoggingError(w, 500, fmt.Sprintf("Unable to determine current offset in log file: %v", err), lfi.EncodedLogLineMetadata)
		return
	}

	// Success; return updated logFileOffset to invoker
	w.WriteHeader(200)
	fmt.Fprintf(w, "%d", logFileOffset)

	if timeOps {
		end := time.Now()
		elapsed := end.Sub(start)
		fmt.Fprintf(os.Stdout, "LogForward took %s\n", elapsed.String())
	}
}

/*
 * Suppout for suspend/resume operations
 */

// handler for /resume route
func resumeUserAction(w http.ResponseWriter, r *http.Request) {
	var start time.Time
	if timeOps {
		start = time.Now()
	}

	vars := mux.Vars(r)
	container := vars["container"]
	dummy := strings.NewReader("")
	resp, err := client.Post("http://localhost/containers/"+container+"/unpause", "text/plain", dummy)
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Unpausing %s failed with error: %v\n", container, err)
	} else if resp.StatusCode < 200 || resp.StatusCode > 299 {
		w.WriteHeader(resp.StatusCode)
		fmt.Fprint(w, "Unpausing %s failed with status code: %d\n", container, resp.StatusCode)
	} else {
		w.WriteHeader(204) // success!
	}

	if timeOps {
		end := time.Now()
		elapsed := end.Sub(start)
		fmt.Fprintf(os.Stdout, "Unpause took %s\n", elapsed.String())
	}
}

// handler for /resume route
func suspendUserAction(w http.ResponseWriter, r *http.Request) {
	var start time.Time
	if timeOps {
		start = time.Now()
	}

	vars := mux.Vars(r)
	container := vars["container"]
	dummy := strings.NewReader("")
	resp, err := client.Post("http://localhost/containers/"+container+"/pause", "text/plain", dummy)
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Pausing %s failed with error: %v\n", container, err)
	} else if resp.StatusCode < 200 || resp.StatusCode > 299 {
		w.WriteHeader(resp.StatusCode)
		fmt.Fprint(w, "Pausing %s failed with status code: %d\n", container, resp.StatusCode)
	} else {
		w.WriteHeader(204) // success!
	}

	if timeOps {
		end := time.Now()
		elapsed := end.Sub(start)
		fmt.Fprintf(os.Stdout, "Pause took %s\n", elapsed.String())
	}
}

/*
 * Initialization and main function
 */

// Process configuration overrides from environment
func initializeFromEnv() {
	var err error
	if os.Getenv("INVOKER_AGENT_DOCKER_SOCK") != "" {
		dockerSock = os.Getenv("INVOKER_AGENT_DOCKER_SOCK")
	}
	if os.Getenv("INVOKER_AGENT_CONTAINER_DIR") != "" {
		containerDir = os.Getenv("INVOKER_AGENT_CONTAINER_DIR")
	}
	if os.Getenv("INVOKER_AGENT_OUTPUT_LOG_DIR") != "" {
		outputLogDir = os.Getenv("INVOKER_AGENT_OUTPUT_LOG_DIR")
	}
	if os.Getenv("INVOKER_AGENT_PORT") != "" {
		str := os.Getenv("INVOKER_AGENT_PORT")
		invokerAgentPort, err = strconv.Atoi(str)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Invalid INVOKER_AGENT_PORT %s; error was %v\n", str, err)
			panic(err)
		}
	}
	if os.Getenv("INVOKER_AGENT_LOG_SINK_SIZE") != "" {
		str := os.Getenv("INVOKER_AGENT_LOG_SINK_SIZE")
		logSinkSize, err = strconv.ParseInt(str, 10, 64)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Invalid INVOKER_AGENT_LOG_SINK_SIZE %s; error was %v\n", str, err)
			panic(err)
		}
	}
}

func handleRequests() {
	myRouter := mux.NewRouter().StrictSlash(true)
	myRouter.HandleFunc("/logs/{container}", forwardLogsFromUserAction)
	myRouter.HandleFunc("/suspend/{container}", suspendUserAction)
	myRouter.HandleFunc("/resume/{container}", resumeUserAction)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", invokerAgentPort), myRouter))
}

func main() {
	initializeFromEnv()

	// Open http client to dockerSock
	fd := func(proto, addr string) (conn net.Conn, err error) {
		return net.Dial("unix", dockerSock)
	}
	tr := &http.Transport{
		Dial: fd,
	}
	client = &http.Client{Transport: tr}

	// initialize logSink subsystem & schedule logWrite go routine
	logSinkChannel = make(chan string)
	go logWriter()

	handleRequests()
}
