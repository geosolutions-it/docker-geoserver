FROM tomcat:9-jdk11-temurin-jammy as mother
LABEL maintainer="Alessandro Parma <alessandro.parma@geosolutionsgroup.com>"
SHELL ["/bin/bash", "-c"]

ARG CORS_ENABLED=false
ARG CORS_ALLOWED_ORIGINS=*
ARG CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
ARG CORS_ALLOWED_HEADERS=*
ARG CORS_ALLOW_CREDENTIALS=false

ENV CORS_ENABLED=$CORS_ENABLED
ENV CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS
ENV CORS_ALLOWED_METHODS=$CORS_ALLOWED_METHODS
ENV CORS_ALLOWED_HEADERS=$CORS_ALLOWED_HEADERS
ENV CORS_ALLOW_CREDENTIALS=$CORS_ALLOW_CREDENTIALS

ARG APP_LOCATION="geoserver"

RUN apt-get update && apt-get install -y unzip

# accepts local files and URLs. Tar(s) are automatically extracted
WORKDIR /output/datadir
ARG GEOSERVER_DATA_DIR_SRC="./.placeholder"
ADD "${GEOSERVER_DATA_DIR_SRC}" "./"

# accepts local files and URLs. Tar(s) are automatically extracted
WORKDIR /output/webapp
ARG GEOSERVER_WEBAPP_SRC="./.placeholder"
ADD "${GEOSERVER_WEBAPP_SRC}" "./"

# zip files require explicit extracion
RUN \
    if [ -f "./download" ] ; then \
      mv download geoserver.war.zip && unzip geoserver.war.zip -d geoserver.war && mkdir -p ./geoserver && unzip ./geoserver.war/geoserver.war -d ./geoserver && rm -rf ./geoserver.war;\
    fi

# zip files require explicit extracion
RUN \
    if [ "${GEOSERVER_WEBAPP_SRC##*.}" = "zip" ]; then \
        unzip "./*zip"; \
        rm ./*zip; \
    fi \
    && [ -d "./geoserver" ] || (mkdir -p ./geoserver && unzip ./geoserver.war -d ./geoserver && rm ./geoserver.war)

WORKDIR /output/plugins
ARG PLUG_IN_URLS=""
ARG PLUG_IN_PATHS=""
ADD .placeholder ${PLUG_IN_PATHS} /output/plugins/
COPY geoserver-plugin-download.sh /usr/local/bin/geoserver-plugin-download.sh
RUN /usr/local/bin/geoserver-plugin-download.sh /output/plugins/ ${PLUG_IN_URLS}
RUN \
    if [ -f *.zip ] ; then \
       unzip -o "./*.zip"; \
    fi

WORKDIR /output/webapp
RUN \
    if [ "${APP_LOCATION}" != "geoserver" ]; then \
      mv /output/webapp/geoserver /output/webapp/${APP_LOCATION}; \
    fi

FROM tomcat:9-jdk11-temurin-jammy

ARG UID=1000
ARG GID=1000
ARG UNAME=tomcat
ARG CUSTOM_FONTS="./.placeholder"
ENV ADMIN_PASSWORD=""
ENV APP_LOCATION="geoserver"

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
# override at run time as needed CATALINA_OPTS
ENV INITIAL_MEMORY="2G"
ENV MAXIMUM_MEMORY="4G"
ENV JAIEXT_ENABLED="true"
ENV PLUGIN_DYNAMIC_URLS=""
ENV EXTRA_GEOSERVER_OPTS=""
ENV GEOSERVER_OPTS=" \
  -Dorg.geotools.coverage.jaiext.enabled=${JAIEXT_ENABLED} \
  -Duser.timezone=UTC \
  -Dorg.geotools.shapefile.datetime=true \
  -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION} \
  -DGEOWEBCACHE_CONFIG_DIR=${GEOWEBCACHE_CONFIG_DIR} \
  -DGEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR} \
  -DNETCDF_DATA_DIR=${NETCDF_DATA_DIR} \
  -DGRIB_CACHE_DIR=${GRIB_CACHE_DIR}"

ENV CATALINA_OPTS="-Xms${INITIAL_MEMORY} -Xmx${MAXIMUM_MEMORY} \
  -Djava.awt.headless=true -server \
  -Dfile.encoding=UTF8 \
  -Djavax.servlet.request.encoding=UTF-8 \
  -Djavax.servlet.response.encoding=UTF-8 \
  -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=20 -XX:ConcGCThreads=5 \
  ${GEOSERVER_OPTS}"

# added for git hash
ARG GIT_HASH=""
ENV GIT_HASH "$GIT_HASH"

COPY run_tests.sh /docker/tests/run_tests.sh

# install needed packages and create externalized dirs
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes git vim gdal-bin postgresql-client fontconfig libfreetype6 jq unzip \
    && apt-get clean \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/doc/* \
    && mkdir -p \
    "${GEOSERVER_DATA_DIR}" \
    "${GEOSERVER_LOG_DIR}"  \
    "${GEOWEBCACHE_CONFIG_DIR}" \
    "${GEOWEBCACHE_CACHE_DIR}" \
    "${NETCDF_DATA_DIR}" \
    "${GRIB_CACHE_DIR}"

# copy from mother
COPY --from=mother "/output/datadir" "${GEOSERVER_DATA_DIR}"
COPY --from=mother "/output/webapp/geoserver" "${CATALINA_BASE}/webapps/geoserver"
COPY --from=mother "/output/plugins" "${CATALINA_BASE}/webapps/geoserver/WEB-INF/lib"

COPY geoserver-plugin-download.sh /usr/local/bin/geoserver-plugin-download.sh
COPY geoserver-rest-config.sh /usr/local/bin/geoserver-rest-config.sh
COPY geoserver-rest-reload.sh /usr/local/bin/geoserver-rest-reload.sh
COPY entrypoint.sh /entrypoint.sh
COPY ${CUSTOM_FONTS} $GEOSERVER_DATA_DIR/styles/
RUN groupadd -g $GID $UNAME
RUN useradd -m -u $UID -g $GID --system $UNAME
RUN chown -R $UID:$GID $GEOSERVER_LOG_DIR $CATALINA_BASE $GEOWEBCACHE_CACHE_DIR $GEOWEBCACHE_CONFIG_DIR $NETCDF_DATA_DIR $GRIB_CACHE_DIR $GEOSERVER_DATA_DIR

RUN if [ ! -f "${GEOSERVER_DATA_DIR}/logging.xml" ]; then cp -a ${CATALINA_BASE}/webapps/geoserver/data/* ${GEOSERVER_DATA_DIR};fi

WORKDIR "$CATALINA_BASE"
USER $UNAME

ENV TERM xterm
EXPOSE 8080/tcp
CMD ["/entrypoint.sh"]
