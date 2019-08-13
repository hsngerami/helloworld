FROM maven:3.5-jdk-8-alpine

ENV TZ=Asia/Tehran

RUN apk add --update --nocache \
        tzdata \
        bash \
        ca-certificates \
        rsync \
    && \

    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \


    rm -rf /var/cache/apk/*

EXPOSE 8080

WORKDIR /app

# Copy the required configuration files into the Docker image. Don't copy the
# application files yet as they prevent `mvn dependency:resolve` from being cached by
# Docker's layer caching mechanism.
COPY pom.xml .
RUN mvn dependency:resolve && \
    mvn verify

# Setup permissions for directories and files that will be written to at runtime.
# These need to be group-writeable for the default Docker image's user.
# To do this, the folders are created, their group is set to the root
# group, and the correct group permissions are added.
RUN mkdir -p /root/.m2 && \
    chmod -R g+rws,a+rx /root/.m2 && \
    chown -R 1001:0 /root/.m2

# Copy the application files, compile and package into a fat jar
COPY . .
RUN mvn package
RUN ls /app/target
RUN mv /app/target/*.jar /app.jar

# Set Java's memory limit to be around half of the pod's memory via JVM_OPTS.
#
# e.g. `JVM_OPTS="-Xms512m -Xmx512m"` when Pod has 1Gi memory.
CMD java $JVM_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar


