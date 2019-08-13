FROM confluentinc/cp-base:5.2.2

ENV TZ=Asia/Tehran

#RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
#    echo "${TZ}" > /etc/timezone && \
RUN wget http://mirrors.supportex.net/apache/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz -O /opt/apache-maven-3.6.1-bin.tar.gz && \
    tar xzvf /opt/apache-maven-3.6.1-bin.tar.gz -C /opt && \
    export PATH=/opt/apache-maven-3.6.1/bin:$PATH


WORKDIR /app

# Copy the required configuration files into the Docker image. Don't copy the
# application files yet as they prevent `mvn dependency:resolve` from being cached by
# Docker's layer caching mechanism.
COPY pom.xml .
ENV MAVEN_CONFIG=/var/maven/.m2
RUN /opt/apache-maven-3.6.1/bin/mvn dependency:resolve && \
    /opt/apache-maven-3.6.1/bin/mvn verify

# Setup permissions for directories and files that will be written to at runtime.
# These need to be group-writeable for the default Docker image's user.
# To do this, the folders are created, their group is set to the root
# group, and the correct group permissions are added.
RUN mkdir -p /var/maven/.m2 && \
    chmod -R g+rws,a+rx /var/maven/.m2 && \
    chown -R 1001:0 /var/maven/.m2

# Copy the application files, compile and package into a fat jar
COPY . .
RUN /opt/apache-maven-3.6.1/bin/mvn package
RUN echo $(ls -1 /app/target)
RUN mv target/*.jar app.jar

# Set Java's memory limit to be around half of the pod's memory via JVM_OPTS.
#
# e.g. `JVM_OPTS="-Xms512m -Xmx512m"` when Pod has 1Gi memory.
CMD java $JVM_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app/app.jar


