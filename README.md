# GeoServer Docker

The [GeoSolutions](https://www.geosolutionsgroup.com/) official configuration to create a simple Docker image for [GeoServer](http://geoserver.org/).  There are two ways that you can get the image and run it. The first option is using DockerHub and the second option is to clone this repository and build the image locally.

## Prerequisites


You need to have [Docker installed](https://www.docker.com/ in your system. You should be able to then open the terminal and run Docker commands.


## Getting the Image and Running it from Docker Hub

The built image is available on [Docker Hub](https://hub.docker.com/r/geosolutionsit/geoserver/). To pull the image type:

`docker pull geosolutionsit/geoserver`

To run the image type:

`docker run --name gs -p 8080:8080 geosolutionsit/geoserver`

This command creates a new container named *gs* based on the *geosolutionsit/geoserver* image. The command is also telling Docker to use port *8080:8080* to run the application.

To verify the installation open your browser and point it to `http://localhost:8080/geoserver`. The GeoServer web interface will show up.


There are some [**environment variables**](https://docs.docker.com/engine/reference/run/) that you can use at run time. For example setting up the memory for JAVA:
- `JAVA_OPTS` to customize JAVA_OPTS for the container


## Building the Image and Running it Locally 
If you want to build the image by yourself just run `docker build` from the root of the repository:

` docker build -t geoserver:test .`

There are a number of [**build arguments**](https://docs.docker.com/engine/reference/commandline/build/) that you can use for customization:

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
