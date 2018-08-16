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
	"fmt"
	"github.com/gorilla/mux"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

/* Should we measure and report time taken for each operation? */
const timeOps = false

/* configuration variables; may be overridden by setting matching envvar */
var (
	dockerSock       string = "/var/run/docker.sock"
	containerDir     string = "/containers"
	invokerAgentPort int    = 3233
)

/* http.Client instance bound to dockerSock */
var client *http.Client


/*
 * Suppout for suspend/resume operations
 */

// handler for /resume/<container> route
// The container was given as part of the URL; gorilla makes it available in vars["container"]
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
		w.WriteHeader(500)
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

// handler for /resume/<container> route
// The container was given as part of the URL; gorilla makes it available in vars["container"]
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
		w.WriteHeader(500)
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
	if os.Getenv("INVOKER_AGENT_PORT") != "" {
		str := os.Getenv("INVOKER_AGENT_PORT")
		invokerAgentPort, err = strconv.Atoi(str)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Invalid INVOKER_AGENT_PORT %s; error was %v\n", str, err)
			panic(err)
		}
	}
}

func handleRequests() {
	myRouter := mux.NewRouter().StrictSlash(true)
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

	handleRequests()
}
