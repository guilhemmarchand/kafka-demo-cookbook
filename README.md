# kafka-demo-cookbook
Kafka Smart Monitoring / Kafka Connect for Splunk demo cookbook

## Tooling

### kafka docker templates (Confluent images and custom pre-built config)

    git clone https://github.com/guilhemmarchand/kafka-docker-splunk.git

### kafka-data-gen

    git clone https://github.com/dtregonning/kafka-data-gen.git   

## Start the lab environment

**To run a Splunk instance in Docker in the guest:**

    cd kafka-docker-splunk/template_docker_splunk_ondocker/
    for container in zookeeper-1 zookeeper-2 zookeeper-3; do; docker-compose up -d $container; done
    for container in kafka-1 kafka-2 kafka-3; do; docker-compose up -d $container; done
    docker-compose up -d kafka-connect-1
    docker-compose up -d telegraf
    docker-compose up -d splunk

*Optionally:*

    docker-compose up -d kafka-burrow
    docker-compose up -d kafka-monitor

*Confluent Optionally:*

    docker-compose up -d schema-registry
    docker-compose up -d ksql-server
    docker-compose up -d kafka-rest

**To use a Splunk instance running locally or elsewhere:**

    cd kafka-docker-splunk/template_docker_splunk_localhost/

*If the Splunk instance is hosted elsewhere than the host, edit docker-compose.yml and update the HEC target*

    for container in zookeeper-1 zookeeper-2 zookeeper-3; do; docker-compose up -d $container; done
    for container in kafka-1 kafka-2 kafka-3; do; docker-compose up -d $container; done
    docker-compose up -d kafka-connect-1
    docker-compose up -d telegraf

*Optionally:*

    docker-compose up -d kafka-burrow
    docker-compose up -d kafka-monitor

*Confluent Optionally:*

    docker-compose up -d schema-registry
    docker-compose up -d ksql-server
    docker-compose up -d kafka-rest

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

## Demo basic Kafka ingestion

