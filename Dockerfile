FROM tomcat:9-jdk11-openjdk-slim as mother
LABEL maintainer="Alessandro Parma<alessandro.parma@geo-solutions.it>"

ENV DEBIAN_FRONTEND noninteractive
ENV CATALINA_BASE "$CATALINA_HOME"

# local dir, tar or remore URLs
ARG GEOSERVER_DATA_DIR_SRC="./.placeholder"
ENV GEOSERVER_DATA_DIR_SRC="${GEOSERVER_DATA_DIR_SRC}"
ADD "${GEOSERVER_DATA_DIR_SRC}" "${GEOSERVER_DATA_DIR}"

# accepts local files and URLs. Tar(s) are automatically extracted
ARG GEOSERVER_WEBAPP_SRC="./.placeholder"
ENV GEOSERVER_WEBAPP_SRC="${GEOSERVER_WEBAPP_SRC}"
ADD "${GEOSERVER_WEBAPP_SRC}" "${CATALINA_BASE}/webapps/"

# zip files require explicit extracion
RUN \
    cd "${CATALINA_BASE}/webapps/"; \
    if [ "${GEOSERVER_WEBAPP_SRC##*.}" = "zip" ]; then \
        apt-get update -y \
        apt-get install -y unzip \
        unzip "./*zip"; \
        rm ./*zip; \
    fi

FROM tomcat:9-jdk11-openjdk-slim

ENV CATALINA_BASE "$CATALINA_HOME"
# set externalizations
ENV GEOSERVER_HOME="/var/geoserver"
ENV GEOSERVER_LOG_DIR="${GEOSERVER_HOME}/logs"
ENV GEOSERVER_DATA_DIR="${GEOSERVER_HOME}/datadir"
ENV GEOSERVER_LOG_LOCATION="${GEOSERVER_LOG_DIR}/geoserver.log"
ENV GEOWEBCACHE_CONFIG_DIR="${GEOSERVER_DATA_DIR}/gwc"
ENV GEOWEBCACHE_CACHE_DIR="${GEOSERVER_HOME}/gwc_cache_dir"
ENV NETCDF_DATA_DIR="${GEOSERVER_HOME}/netcdf_data_dir"
ENV GRIB_CACHE_DIR="${GEOSERVER_HOME}/grib_cache_dir"

# create externalized dirs
RUN mkdir -p \
    "${GEOSERVER_DATA_DIR}" \
    "${GEOSERVER_LOG_DIR}"  \
    "${GEOWEBCACHE_CONFIG_DIR}" \
    "${GEOWEBCACHE_CACHE_DIR}" \
    "${NETCDF_DATA_DIR}" \
    "${GRIB_CACHE_DIR}"

# override at run time as needed JAVA_OPTS
ENV INITIAL_MEMORY="2G" 
ENV MAXIMUM_MEMORY="4G"

ENV GEOSERVER_OPTS=" \
  -DJAIEXT_ENABLED=true \
  -Duser.timezone=GMT \
  -Dorg.geotools.shapefile.datetime=true \
  -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION} \
  -DGEOWEBCACHE_CONFIG_DIR=${GEOWEBCACHE_CONFIG_DIR} \
  -DGEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR} \
  -DNETCDF_DATA_DIR=${NETCDF_DATA_DIR} \
  -DGRIB_CACHE_DIR=${GRIB_CACHE_DIR}"

ENV JAVA_OPTS="-Xms${INITIAL_MEMORY} -Xmx${MAXIMUM_MEMORY} \
  -Djava.awt.headless=true -server \
  -Dfile.encoding=UTF8 \
  -Djavax.servlet.request.encoding=UTF-8 \
  -Djavax.servlet.response.encoding=UTF-8 \
  -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=20 -XX:ConcGCThreads=5 \
  ${GEOSERVER_OPTS}"

COPY --from=mother "${GEOSERVER_DATA_DIR}" "${GEOSERVER_DATA_DIR}"
COPY --from=mother "${CATALINA_BASE}/webapps" "${CATALINA_BASE}/webapps"

WORKDIR "$CATALINA_BASE"

ENV TERM xterm
EXPOSE 8080/tcp
