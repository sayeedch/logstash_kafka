FROM centos:7
LABEL maintainer sayeedch

# Path to latest Logstash version
ENV LS_PATH=https://artifacts.elastic.co/downloads/logstash/logstash-5.5.2.tar.gz
    X_PACK=https://artifacts.elastic.co/downloads/packs/x-pack/x-pack-5.5.2.zip

ENV LOGSTASH_HOME=/opt/logstash

# Use the appropriate Logstash and X-Pack versions
ENV LOGSTASH_VERSION=5.5.2 
ENV ELASTICSEARCH_SERVICE_HOST=elasticsearch 
ENV X_PACK_VERSION=5.5.2

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y java-1.8.0-openjdk-devel which && \
    yum clean all


# Addd path to Logstash 
ENV PATH=${LOGSTASH_HOME}/bin:$PATH

USER root

#COPY logstash-5.5.2.tar.gz /opt
#COPY x-pack-5.5.2.zip /opt
    

LABEL io.k8s.description="Logstash" \
      io.k8s.display-name="logstash ${LOGSTASH_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="logstash,${LOGSTASH_VERSION},elk"


RUN mkdir -p /opt/

# Add Logstash 
# Move contents of logstash-version folder to ${LOGSTASH_HOME}
# Change directory ownership to Logstash user 
# Remove tar file

RUN  curl -O $(LS_PATH) && \
  tar zxvf /opt/logstash-${LOGSTASH_VERSION}.tar.gz -C /opt && \
  mv /opt/logstash-${LOGSTASH_VERSION}/ ${LOGSTASH_HOME} && \
#  chown --recursive logstash:logstash ${LOGSTASH_HOME}/ && \
#  ln -s ${LOGSTASH_HOME} /opt/logstash 
  rm -f /opt/logstash-${LOGSTASH_VERSION}.tar.gz 

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir ${LOGSTASH_HOME} --no-create-home \
      logstash


# Provide a minimal configuration, so that simple invocations will provide
#ADD config/logstash.yml config/log4j2.properties ${LOGSTASH_HOME}/config/
ADD pipeline/logstash.conf ${LOGSTASH_HOME}/pipeline/logstash.conf
RUN chmod -R 777 ${LOGSTASH_HOME}
#RUN chown --recursive logstash:logstash ${LOGSTASH_HOME}/config/ ${LOGSTASH_HOME}/pipeline/

# Ensure Logstash gets a UTF-8 locale by default.
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'

# Set user to Logstash
USER 1000

# Download and install X-Pack for Logstash
RUN \
  curl -o ${X_PACK} && \
  cd ${LOGSTASH_HOME} && logstash-plugin install x-pack && \
  rm x-pack-${X_PACK_VERSION}.zip

WORKDIR ${LOGSTASH_HOME}

ENTRYPOINT [ "bin/logstash", "-f pipeline/logstash.conf" ]

EXPOSE 9600 5044
