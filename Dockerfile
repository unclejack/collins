FROM java:8-jdk
MAINTAINER Gabe Conradi <gabe@tumblr.com>

RUN apt-get update && apt-get install -y zip unzip && rm -r /var/lib/apt/lists/*

# Solr cores should be stored in a volume, so we arent writing stuff to our rootfs
VOLUME /opt/collins/conf/solr/cores/collins/data

COPY . /build/collins
RUN cd /build && \
    export ACTIVATOR_VERSION=1.3.7 && \
    wget -q http://downloads.typesafe.com/typesafe-activator/$ACTIVATOR_VERSION/typesafe-activator-$ACTIVATOR_VERSION-minimal.zip -O /build/activator.zip && \
    unzip -q ./activator.zip && \
    cd collins && \
    java -version 2>&1 && \
    PLAY_CMD=/build/activator-$ACTIVATOR_VERSION-minimal/activator ./scripts/package.sh && \
    unzip -q /build/collins/target/collins.zip -d /opt/ && \
    cd / && rm -rf /build

WORKDIR /opt/collins

# Add in all the default configs we want in this build so collins can run.
# You probably will want to override these configs in production
COPY conf/docker conf/

# expose HTTP, JMX
EXPOSE 9000 3333
CMD ["/usr/bin/java","-server","-Dconfig.file=/opt/collins/conf/production.conf","-Dhttp.port=9000","-Dlogger.file=/opt/collins/conf/logger.xml","-Dnetworkaddress.cache.ttl=1","-Dnetworkaddress.cache.negative.ttl=1","-Dcom.sun.management.jmxremote","-Dcom.sun.management.jmxremote.port=3333","-Dcom.sun.management.jmxremote.authenticate=false","-Dcom.sun.management.jmxremote.ssl=false","-XX:MaxPermSize=384m","-XX:+CMSClassUnloadingEnabled","-cp","/opt/collins/lib/*","play.core.server.NettyServer","/opt/collins"]

