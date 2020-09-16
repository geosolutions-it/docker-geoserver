# docker-geoserver
Dockerfile to build a Docker image for [GeoServer](http://geoserver.org/). Built image available on [Docker Hub](https://hub.docker.com/r/geosolutionsit/geoserver/)

## How to run it
Pull the image from [Docker Hub](https://hub.docker.com/r/geosolutionsit/geoserver/)

`docker pull geosolutionsit/geoserver`

And run it

`docker run --name gs -p 8080:8080 geosolutionsit/geoserver`

Open your browser and point it to `http://localhost:8080/geoserver` . GeoServer web interface will show up


There are some [**environment variables**](https://docs.docker.com/engine/reference/run/) you can use at run time:
- `JAVA_OPTS` to customize JAVA_OPTS for the container


## How to build it
If you want to build the image by yourself just run `docker build` from the root of the repository

` docker build -t geoserver:test .`

There are a number of [**build arguments**](https://docs.docker.com/engine/reference/commandline/build/) you can use for customization:

- `GEOSERVER_HOME` Base path for GeoServer directory hierarchy. By default will put everything under this directory (data directory, log files, audit files, cached tiles)
- `GEOSERVER_DATA_DIR` Path for GeoServer data directory
- `GEOSERVER_AUDIT_PATH` Path for GeoServer audit files directory
- `GEOSERVER_LOG_LOCATION` Path for GeoServer log files directory
- `GEOWEBCACHE_CACHE_DIR` Path for cached tiles directory
- `INCLUDE_GS_WAR` Include GeoServer war from `./resources/geoserver` in the image?
- `PLUGINS_DIR` Path to GeoServer plugins to include in the build
- `INCLUDE_DATA_DIR`Include GeoServer data directory from `./resources/geoserver-datadir` in the image?
- `TOMCAT_EXTRAS` Delete default Tomcat applications from webapps directory (manager, examples, etc ...) ?
- `GEOSERVER_APP_NAME` Name of the GeoServer war copied into the image (defaults to `geoserver`)
