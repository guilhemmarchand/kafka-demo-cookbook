# kafka-demo-cookbook

Kafka Smart Monitoring / Kafka Connect for Splunk demo cookbook

## Tooling

### kafka docker templates (Confluent images and custom pre-built config)

    git clone https://github.com/guilhemmarchand/kafka-docker-splunk.git

_Any Splunk configuration as index or sourcetype definition required in the following demos are already available to the Splunk instance if you use the Splunk On Docker template._

## Start the lab environment

**To run a Splunk instance in Docker in the guest:**

    cd kafka-docker-splunk/template_docker_splunk_ondocker/

    docker compose up -d --no-deps splunk

    sleep 15

    docker compose up -d zookeeper-1
    docker compose up -d zookeeper-2
    docker compose up -d zookeeper-3

    sleep 15

    docker compose up -d kafka-1
    docker compose up -d kafka-2
    docker compose up -d kafka-3

    sleep 15

    docker compose up -d kafka-connect-1
    docker compose up -d telegraf
    docker compose up -d kafka-data-gen

_Optionally:_

    docker compose up -d burrow
    docker compose up -d kafka-monitor

_Confluent Optionally:_

    docker compose up -d schema-registry
    docker compose up -d ksql-server
    docker compose up -d kafka-rest

**To use a Splunk instance running locally or elsewhere:**

    cd kafka-docker-splunk/template_docker_splunk_localhost/

_If the Splunk instance is hosted elsewhere than the host, edit docker compose.yml and update the HEC target_

    docker compose up -d zookeeper-1
    docker compose up -d zookeeper-2
    docker compose up -d zookeeper-3

    sleep 15

    docker compose up -d kafka-1
    docker compose up -d kafka-2
    docker compose up -d kafka-3

    sleep 15

    docker compose up -d kafka-connect-1
    docker compose up -d telegraf
    docker compose up -d kafka-data-gen

_Optionally:_

    docker compose up -d burrow
    docker compose up -d kafka-monitor

_Confluent Optionally:_

    docker compose up -d schema-registry
    docker compose up -d ksql-server
    docker compose up -d kafka-rest

## Kafka Smart Monitoring app for Splunk

Access the Splunk UI: (if running in Docker / localhost)

http://localhost:8000

Install the Kafka Smart Monitoring app:

https://splunkbase.splunk.com/app/4268/

If Splunk is not running in Docker with provided templates, you can simple install these base config apps to pre-configure an HEC token, indexers and some other configuration items:

https://github.com/guilhemmarchand/kafka-docker-splunk/tree/master/splunk

- TA-docker-kafka
- TA-telegraf-kafka

Once everything is up and running, the UI would show components discovered:

![screenshot1](./img/app_main.png)

## Demo 1: ingestion with the HEC event endpoint

The most convenient and the most performing way of ingesting Kafka messages in Splunk is to target the HEC event endpoint.

However, there are strict limitations regarding the date time parsing capabilities, unless specific in a specific format in a specific way, the \_time will be equal to the ingestion time in Splunk, often enough this may not be compliant with the requirements. (the time stamp is not accurate, delay in the ingestion would cause even more inaccuracy)

- Generate 1 million of messages in a topic: "kafka_demo"

```

cd kafka-docker-splunk/template_docker_splunk_<replace with your context>
docker compose exec kafka-data-gen /bin/bash

java -jar /app/kafka-data-gen.jar -message-count 1000000 -message-size 256 -topic kafka_demo1 -bootstrap.servers "kafka-1:19092,kafka-2:29092,kafka-3:39092" -acks all -kafka-retries 0 -kafka-batch-size 60000 -kafka-linger 1 -kafka-buffer-memory 33554432 -eps 0 -output-eventhubs false -output-kafka true -output-stdout false
```

- Create an index in Splunk named "kafka_demo"

- Create a new HEC token, do no specifiy any sourcetype / source and select the default index to be kafka_demo

- Create a new Sink connector:

_modify the HEC target if Splunk is not running in Docker_

_modify the HEC token accordingly_

_run the curl command on a new terminal_

```json
curl localhost:18082/connectors -X POST -H "Content-Type: application/json" -d '{
"name": "sink-splunk-demo1",
"config": {
   "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
   "tasks.max": "1",
   "topics":"kafka_demo1",
   "splunk.indexes": "kafka_demo",
   "splunk.sourcetypes": "kafka:gen",
   "splunk.sources": "kafka:west:emea:demo1",
   "splunk.hec.uri": "https://splunk:8088",
   "splunk.hec.token": "1f2e3966-14ad-11eb-9bfa-acde48001122",
   "splunk.hec.raw": "false",
   "splunk.hec.ssl.validate.certs": "false"
  }
}'
```

The topic activity will be visible in the Kafka Smart monitoring interface, and data should be ingested in Splunk.

_Splunk search example:_

```
index=kafka_demo sourcetype=kafka:gen source=kafka:west:emea:demo1
| eval latency_time_to_indextime=(_indextime-_time)
| eval timestamp_epoch=strptime(timestamp, "%Y-%m-%d %H:%M:%S.%3N")
| eval latency_indextime_to_raw_timestamp=_indextime-timestamp_epoch
| timechart span=1m count as eventcount, avg(latency_time_to_indextime) as latency_time_to_indextime, avg(latency_indextime_to_raw_timestamp) as latency_indextime_to_raw_timestamp
```

## Demo 2: ingestion with the HEC raw endpoint

- Generate 1 million of messages in a topic: "kafka_demo"

```

cd kafka-docker-splunk/template_docker_splunk_<replace with your context>
docker compose exec kafka-data-gen /bin/bash

java -jar /app/kafka-data-gen.jar -message-count 1000000 -message-size 256 -topic kafka_demo2 -bootstrap.servers "kafka-1:19092,kafka-2:29092,kafka-3:39092" -acks all -kafka-retries 0 -kafka-batch-size 60000 -kafka-linger 1 -kafka-buffer-memory 33554432 -eps 0 -output-eventhubs false -output-kafka true -output-stdout false
```

- Define a new sourcetype in Splunk (props.conf)

```
[kafka:gen]
SHOULD_LINEMERGE=false
LINE_BREAKER = (####)
SHOULD_LINEMERGE = false
CHARSET=UTF-8
TIME_PREFIX=\"timestamp\":\"
TIME_FORMAT=%Y-%m-%d %H:%M:%S.%3N
MAX_TIMESTAMP_LOOKAHEAD=30
TRUNCATE=0
```

- Create a new Sink connector:

_modify the HEC target if Splunk is not running in Docker_

_modify the HEC token accordingly_

_run the curl command on a new terminal_

```json
curl localhost:18082/connectors -X POST -H "Content-Type: application/json" -d '{
"name": "sink-splunk-demo2",
"config": {
   "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
   "tasks.max": "1",
   "topics":"kafka_demo2",
   "splunk.indexes": "kafka_demo",
   "splunk.sourcetypes": "kafka:gen",
   "splunk.sources": "kafka:west:emea:demo2",
   "splunk.hec.uri": "https://splunk:8088",
   "splunk.hec.token": "1f2e3966-14ad-11eb-9bfa-acde48001122",
   "splunk.hec.raw": "true",
   "splunk.hec.raw.line.breaker" : "####",
   "splunk.hec.ssl.validate.certs": "false"
  }
}'
```

This time the data is ingested using thw raw enedpoint, the events breaking relies on a delimitor created by the Splunk sink connector plugin and the sourcetype definition.

_Splunk search example:_

```
index=kafka_demo sourcetype=kafka:gen source=kafka:west:emea:demo2
| eval latency_time_to_indextime=(_indextime-_time)
| eval timestamp_epoch=strptime(timestamp, "%Y-%m-%d %H:%M:%S.%3N")
| eval latency_indextime_to_raw_timestamp=_indextime-timestamp_epoch
| timechart span=1m count as eventcount, avg(latency_time_to_indextime) as latency_time_to_indextime, avg(latency_indextime_to_raw_timestamp) as latency_indextime_to_raw_timestamp
```

## Demo 3: ingestion with the HEC event endpoint using Kafka headers

In advanced setups, we could use the Kafka headers (that would need to be generated by the producer of the messages) to recycle the Kafka header informaton automatically in Splunk to route traffic to the index target, or sourcetype, host etc.

**Kafka headers can only be used with the event endpoint.**

_kafka header example:_

```
Key (1 bytes): 2
Value (408 bytes): {"timestamp":"2020-10-16 06:34:39.411", "region": "emea", "company":"acme", "eventKey":"2", "uuid":"2469a3db-359c-479b-bc6c-ac6115250585", "message":"miqrqrdsrcsxcknoskdczjgynfqkihshezckjrhhytrejsjqeqepuwzdbgribpbilswoixylwempjffqpoqdgjmwlrfojtxarmjsnmtcpmwpkqcajyhlhmezxqbulqvgelmfhrkowonptfyusyeugwhcbbqvjjbvkbllnhvqguknwzveawqqcvhahudxplspngtubnykwsyhurjbqmxipmzqrwwobfhuygpjsurcuwuemkuoyuoahtyeoiknmmec"}
Headers: header_index=kafka_demo_acme,header_host=kafka.west,header_source=kafka:west:amer,header_sourcetype=kafka:gen,company=acme,region=emea
Partition: 0	Offset: 9
```

- Generate a few messages in a new topic named "kafka_demo_headers" to verify the headers

```

cd kafka-docker-splunk/template_docker_splunk_<replace with your context>
docker compose exec kafka-data-gen /bin/bash

java -jar /app/kafka-data-gen.jar -message-count 5 -message-size 256 -topic kafka_demo_headers -bootstrap.servers "kafka-1:19092,kafka-2:29092,kafka-3:39092" -acks all -kafka-retries 0 -kafka-batch-size 60000 -kafka-linger 1 -kafka-buffer-memory 33554432 -eps 0 -output-eventhubs false -output-kafka true -output-stdout false -generate-kafka-headers true -header-gen-profile 0
```

A powerful way to vizualise these headers is to use kafkacat, example (from in within docker)

```
docker run --network=host --tty --interactive --rm \
           edenhill/kafkacat:1.6.0 \
           kafkacat -b kafka-1:19092 \
           -C \
           -f '\nKey (%K bytes): %k\t\nValue (%S bytes): %s\nHeaders: %h\n\Partition: %p\tOffset: %o\n--\n' \
           -t kafka_demo_headers
```

- Create a new HEC token, do no specifiy any sourcetype / source and select the default index to be **main**

- Create a new index named **kafka_demo_acme** and add this index to the list of allowed indexed in the token definition

- Create a new Sink connector:

_modify the HEC target if Splunk is not running in Docker_

_modify the HEC token accordingly_

_run the curl command on a new terminal_

```json
curl localhost:18082/connectors -X POST -H "Content-Type: application/json" -d '{
"name": "sink-splunk-demo3",
"config": {
   "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
   "tasks.max": "1",
   "topics":"kafka_demo_headers",
   "splunk.hec.uri": "https://splunk:8088",
   "splunk.hec.token": "1f2e3966-14ad-11eb-9bfa-acde48001122",
   "splunk.hec.raw": "false",
   "splunk.header.support": "true",
   "splunk.header.custom": "company,region",
   "splunk.header.index": "header_index",
   "splunk.header.source": "header_source",
   "splunk.header.sourcetype": "header_sourcetype",
   "splunk.header.host": "header_host",
   "splunk.hec.ssl.validate.certs": "false"
  }
}'
```

- Generate 1 million of messages in a topic: "kafka_demo_headers"

```

cd kafka-docker-splunk/template_docker_splunk_<replace with your context>
docker compose exec kafka-data-gen /bin/bash

java -jar /app/kafka-data-gen.jar -message-count 1000000 -message-size 256 -topic kafka_demo_headers -bootstrap.servers "kafka-1:19092,kafka-2:29092,kafka-3:39092" -acks all -kafka-retries 0 -kafka-batch-size 60000 -kafka-linger 1 -kafka-buffer-memory 33554432 -eps 0 -output-eventhubs false -output-kafka true -output-stdout false -generate-kafka-headers true -header-gen-profile 0
```

Definition of Splunk Metadata in addition with the creation of two indexed fields (company and region) are handled automatically by the Sink connector relying on the Kafka headers.

_Splunk search example:_

```
index=kafka_demo_acme sourcetype=kafka:gen
| eval latency_time_to_indextime=(_indextime-_time)
| eval timestamp_epoch=strptime(timestamp, "%Y-%m-%d %H:%M:%S.%3N")
| eval latency_indextime_to_raw_timestamp=_indextime-timestamp_epoch
| timechart span=1m count as eventcount, avg(latency_time_to_indextime) as latency_time_to_indextime, avg(latency_indextime_to_raw_timestamp) as latency_indextime_to_raw_timestamp
```

## Managing connectors

_Getting the list of plugins available in Kafka Connect:_

    curl localhost:18082/connector-plugins

_Getting the list of sink connectors configured:_

    curl localhost:18082/connectors

_List config for each:_

```
curl localhost:18082/connectors/sink-splunk-demo1

curl localhost:18082/connectors/sink-splunk-demo2

curl localhost:18082/connectors/sink-splunk-demo3
```

_Getting tasks:_

    curl localhost:18082/connectors/tasks

_Pause a connector:_

    curl -X PUT localhost:18082/connectors/sink-splunk-demo1/pause

_Resume a connector:_

    curl -X PUT localhost:18082/connectors/sink-splunk-demo1/resume

_Delete connectors:_

```
curl -X DELETE localhost:18082/connectors/sink-splunk-demo1

curl -X DELETE localhost:18082/connectors/sink-splunk-demo2

curl -X DELETE localhost:18082/connectors/sink-splunk-demo3
```
