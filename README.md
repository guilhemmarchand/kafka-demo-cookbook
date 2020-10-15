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
    docker-compose up -d -kafka-monitor

**To use a Splunk instance running locally or elsewhere:**

    cd kafka-docker-splunk/template_docker_splunk_localhost/

*If the Splunk instance is hosted elsewhere than the host, edit docker-compose.yml and update the HEC target*

    for container in zookeeper-1 zookeeper-2 zookeeper-3; do; docker-compose up -d $container; done
    for container in kafka-1 kafka-2 kafka-3; do; docker-compose up -d $container; done
    docker-compose up -d kafka-connect-1
    docker-compose up -d telegraf

*Optionally:*

    docker-compose up -d kafka-burrow
    docker-compose up -d -kafka-monitor

