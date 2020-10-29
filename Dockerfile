FROM openjdk:latest

EXPOSE 8080

RUN mkdir /app

COPY *.jar /app/kafka-data-gen.jar

ENTRYPOINT ["tail", "-f", "/dev/null"]
