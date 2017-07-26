#!/bin/bash

set -m
/start.sh &

TIMEOUT=0
PASSED=false
echo "wait for Kafka to be up and running"
until [ $TIMEOUT -eq 25 ]; do
  echo "waiting for kafka to be available"

  nc -z 127.0.0.1 $KAFKA_PORT
  if [ $? -eq 0 ]; then
    echo "kafka is up and running"
    PASSED=true
    break
  fi

  sleep 0.2
  let TIMEOUT=TIMEOUT+1
done

if [ $PASSED = false ]; then
  echo "failed to setup and reach kafka"
  exit 1
fi

unset JMX_PORT

set -x

echo "Create health topic"
OUTPUT=$(kafka-topics.sh --create --topic health --replication-factor $REPLICATION_FACTOR --partitions $PARTITIONS --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_PORT} --config retention.bytes=$KAFKA_TOPICS_HEALTH_RETENTIONBYTES --config retention.ms=$KAFKA_TOPICS_HEALTH_RETENTIONMS --config segment.bytes=$KAFKA_TOPICS_HEALTH_SEGMENTBYTES)
if ! ([[ "$OUTPUT" == *"already exists"* ]] || [[ "$OUTPUT" == *"Created topic"* ]]); then
  echo "Failed to create heath topic"
  exit 1
fi

echo "Create completed topics"
CONTROLLER_COUNT=$((CONTROLLER_COUNT - 1))
for i in `seq 0 $CONTROLLER_COUNT`; do
  OUTPUT=$(kafka-topics.sh --create --topic completed$i --replication-factor $REPLICATION_FACTOR --partitions $PARTITIONS --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_PORT} --config retention.bytes=$KAFKA_TOPICS_COMPLETED_RETENTIONBYTES --config retention.ms=$KAFKA_TOPICS_COMPLETED_RETENTIONMS --config segment.bytes=$KAFKA_TOPICS_COMPLETED_SEGMENTBYTES)

  if ! ([[ "$OUTPUT" == *"already exists"* ]] || [[ "$OUTPUT" == *"Created topic"* ]]); then
    echo "Failed to create completed$i topic"
    exit 1
  fi
done

echo "Create invoker topics"
INVOKER_COUNT=$((INVOKER_COUNT - 1))
for i in `seq 0 $INVOKER_COUNT`; do
  OUTPUT=$(kafka-topics.sh --create --topic invoker$i --replication-factor $REPLICATION_FACTOR --partitions $PARTITIONS --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_PORT} --config retention.bytes=$KAFKA_TOPICS_INVOKER_RETENTIONBYTES --config retention.ms=$KAFKA_TOPICS_INVOKER_RETENTIONMS --config segment.bytes=$KAFKA_TOPICS_INVOKER_SEGMENTBYTES)

  if ! ([[ "$OUTPUT" == *"already exists"* ]] || [[ "$OUTPUT" == *"Created topic"* ]]); then
    echo "Failed to create invoker$i topic"
    exit 1
  fi
done

fg
