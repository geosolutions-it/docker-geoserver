FROM tomcat:7.0-jre8
MAINTAINER Alessandro Parma<alessandro.parma@geo-solutions.it>

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl
#RUN  ln -s /bin/true /sbin/initctl

# Install updates
RUN apt-get -y update

#------------- Copy resources from local file system --------------------------
ONBUILD ADD resources /tmp/resources

#------------- GeoServer Specific Stuff ---------------------------------------
ENV CATALINA_BASE $CATALINA_HOME

# Set env vars for  GeoServer 
ARG GEOSERVER_HOME="/var/geoserver"
ARG GEOSERVER_DATA_DIR="${GEOSERVER_HOME}/datadir"
ARG GEOSERVER_AUDIT_PATH="${GEOSERVER_HOME}/audits"
ARG GEOSERVER_LOG_LOCATION="${GEOSERVER_HOME}/logs"
ARG GEOWEBCACHE_CACHE_DIR="${GEOSERVER_HOME}/gwc_cache_dir"

# Set default JAVA_OPTS (override as needed at run time)
ENV JAVA_OPTS="-Xms1024m -Xmx1024m -XX:+UseParallelGC -XX:+UseParallelOldGC \
    -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR} \
    -DGEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR} \
    -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}/geoserver.log"

# Create GeoServer directories
RUN    mkdir -p $GEOSERVER_DATA_DIR   \
    && mkdir -p $GEOSERVER_AUDIT_PATH \
    && mkdir -p $GEOSERVER_LOG_LOCATION \
    && mkdir -p $GEOWEBCACHE_CACHE_DIR

# Optionally remove Tomcat manager, docs, and examples
ARG TOMCAT_EXTRAS=false
ONBUILD RUN \
    if [ "$TOMCAT_EXTRAS" = false ]; then \
        rm -rf "${CATALINA_HOME}/webapps/*" \
    ; fi

# Move GeoServer war into Tomcat webapps dir
ONBUILD RUN mv /tmp/resources/geoserver/geoserver.war ${CATALINA_BASE}/webapps/geoserver.war

# Install any plugin zip files in resources/geoserver-plugins
ONBUILD RUN \
    if ls /tmp/resources/geoserver-plugins/*.zip > /dev/null 2>&1; then \
      for p in /tmp/resources/geoserver-plugins/*.zip; do \
        unzip $p -d /tmp/gs_plugin \
        && mv /tmp/gs_plugin/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
        && rm -rf /tmp/gs_plugin; \
      done; \
    fi

# Include local data dir in image
ARG INCLUDE_DATA_DIR=false
ONBUILD RUN if [ "$INCLUDE_DATA_DIR" = true ]; then \
    cp -a /tmp/resources/geoserver-datadir/* "$GEOSERVER_DATA_DIR" \
    && rm -rf /tmp/resources/geoserver-datadir \
    ; fi

#------------- Cleanup --------------------------------------------------------

# Delete resources after installation
ONBUILD RUN    rm -rf /tmp/resources \
            && rm -rf /var/lib/apt/lists/*

WORKDIR $CATALINA_HOME

ENV TERM xterm

EXPOSE 8080
