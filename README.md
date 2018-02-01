# docker-geoserver
Docker Image for GeoServer

Build time settings
-------------------
The bulid args listed below gives some flexibility about how we want to build the image. Most of them are self explanatory:

- `BASE_IMAGE_NAME` and `BASE_IMAGE_TAG`: Base image to build from, in this case GeoSolitions "gs-base" available on the Docker hub (https://hub.docker.com/r/geosolutionsit/gs-base), souce code available here (https://github.com/geosolutions-it/docker-geoserver)
- `INCLUDE_DATA_DIR`: whether or not to include the local GeoServer data directory directly into the image at build time instead of mounting it at run time
- `INCLUDE_GS_WAR`:   whether or not to include the local GeoServer WAR directly into the image at build time instead of mounting it at run time
- `INCLUDE_PLUGINS`:  optionally add plugins to the WAR
- `GEOSERVER_HOME`:   used as base directory, relative to the container file system, for GeoServer config, logs, etc...
- `GEOSERVER_DATA_DIR`:     directory, relative to the container file system, for GeoServer datadir (defaults to `${GEOSERVER_HOME}/datadir`)
- `EOWEBCACHE_CACHE_DIR`:  directory, relative to the container file system, for cached tiles (defaults to `{GEOSERVER_HOME}/gwc_cache_dir`)
- `GEOSERVER_AUDIT_PATH`:   directory, relative to the container file system, for Monitor plugin audit files (defaults to `${GEOSERVER_HOME}/audits`)
- `EOSERVER_LOG_LOCATION`: file path, relative to the container file system, for GeoServer logs (defaults to `${GEOSERVER_HOME}/logs`)
- `GEOSERVER_APP_NAME`: controls the webapp name and can also be set as an environment variable at runtime. This allows to have a single docker image for geoserver slaves and geoserver master instances, for instance at run time we set this one to "geoserver" for the slaves and "geoserver-master" for the master instance.
- `JAVA_OPTS`: JVM options. Note that you can user run time environment variables as well by escaping the dollar sign like I did in my example. The purpose of the variables as we used them is exmplained below

Runtime settings
----------------
The `${DOCKER_HOST}`, `${MASTER_SLAVE}`, `${HOSTNAME}` environment variables are set at container run time by the Rancher and allow to properly discern between the various containers and hosts in order to keep the logs and audit file tidy (you can figure out which container running on which host produced the file), avoid clashing between the instances (multiple containers trying to write to the same "geoserver.log" file would cause GeoServer startup to fail). For instance at run time we set:

- `DOCKER_HOST` to `pf-docker-1`
- `GEOSERVER_APP_NAME` to `geoserver-master`
- `MASTER_SLAVE` to `Master`
- `PROXY_BASE_URL` to `http://pf-docker.eoss-cloud.it/geoserver-master/`

Data persistence and Volumes
----------------------------
Based on the specific build time / run time settings we used below we configured the following to persist our changes to the containers file system and share configuration between the containers:

`/var/geoserver/audits` mapped to `/var/geoserver/audits`
`/var/geoserver/logs` mapped to `/var/geoserver/logs`
`/var/geoserver/gwc_cache_dir` mapped to `/var/geoserver/gwc_cache_dir`
`/var/geoserver/datadir` mapped to `/var/geoserver/datadir`

We also configured the following volumes for convenience:
`/var/geoserver/conf/context.xml` mapped to `/usr/local/tomcat/conf/context.xml` - Tomcat context file with JNDI resources and database connection password
`/var/geoserver/wps-output` mapped to `/var/geoserver/wps-output` - GeoServer's WPS processes output directory
`/var/geoserver/backups` mapped to `/var/geoserver/backups` - GeoServer config backups directory

Image build example
-------------------
```
docker build --pull --no-cache \
--build-arg BASE_IMAGE_NAME=gs-base \
--build-arg BASE_IMAGE_TAG=7.0-jre8 \
--build-arg INCLUDE_DATA_DIR=false  \
--build-arg INCLUDE_GS_WAR=true     \
--build-arg INCLUDE_PLUGINS=false   \
--build-arg GEOSERVER_HOME=/var/geoserver \
--build-arg GEOSERVER_DATA_DIR=/var/geoserver/datadir \
--build-arg GEOSERVER_APP_NAME=geoserver \
--build-arg GEOSERVER_LOG_LOCATION=/var/geoserver/logs/\${DOCKER_HOST}-\${MASTER_SLAVE}-\${HOSTNAME}.log \
--build-arg GEOWEBCACHE_CACHE_DIR=/var/geoserver/gwc_cache_dir \
--build-arg GEOSERVER_AUDIT_PATH=/var/geoserver/audits/geoserver-\${DOCKER_HOST}-\${MASTER_SLAVE}-\${HOSTNAME} \
--build-arg JAVA_OPTS="-Xms1024m -Xmx1024m -XX:+UseParallelGC -XX:+UseParallelOldGC -DGEOSERVER_DATA_DIR=/var/geoserver/datadir -DGEOWEBCACHE_CACHE_DIR=/var/geoserver/gwc_cache_dir -DGEOSERVER_LOG_LOCATION=/var/geoserver/logs/\${DOCKER_HOST}-\${MASTER_SLAVE}-\${HOSTNAME}.log -DGEOSERVER_AUDIT_PATH=/var/geoserver/audits/geoserver-\${DOCKER_HOST}-\${MASTER_SLAVE}-\${HOSTNAME} -DPROXY_BASE_URL=\${PROXY_BASE_URL} -DGEOSERVER_NODE_OPTS=id:\${MASTER_SLAVE} -Dorg.geotools.coverage.jaiext.enabled=true" \
--build-arg TOMCAT_EXTRAS=false \
-t geosolutionsit/geoserver:2.13.x-eows\
-f ./Dockerfile .
```

*Note*: With `INCLUDE_GS_WAR` build argument to "true" GeoServer WAR to be added to the image is expected to be at "./resources/geoserver/geoserver.war"

