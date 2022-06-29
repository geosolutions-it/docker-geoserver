# docker-geoserver

![](/docker_hub_deployment.png)

## How to run it

Pull the image from [Docker Hub](https://hub.docker.com/r/geosolutionsit/geoserver/)

`docker pull geosolutionsit/geoserver`

And run it

`docker run --name gs -p 8080:8080 geosolutionsit/geoserver`

Or for data persistence starting with default geoserver datadir (in this example GEOSERVER_DATA_DIR is pointing to `/var/geoserver/datadir`):

```bash
docker run --rm --name gs -p 8080:8080 geosolutionsit/geoserver
```

Save datadir locally to have a starting datadir:

```bash
docker cp gs:/var/geoserver/datadir ./datadir
docker stop gs
```

start GeoServer with data persistence on saved datadir:

```bash
docker run -v datadir:/var/geoserver/datadir --name gs -p 8080:8080 geosolutionsit/geoserver
```

start GeoServer with data persistence on saved datadir and change admin password:
```bash
docker run -e ADMIN_PASSWORD=securepassword -v datadir:/var/geoserver/datadir --name gs -p 8080:8080 geosolutionsit/geoserver
```
Open your browser and point it to `http://localhost:8080/geoserver` .
GeoServer web interface will show up, you can now log in with user admin and password `geoserver`.

There are some [**environment variables**](https://docs.docker.com/engine/reference/run/) you can use at run time:
- `JAVA_OPTS` to customize JAVA_OPTS for the container
- `GEOSERVER_LOG_DIR` to customize log placement
- `GEOSERVER_DATA_DIR` to put your GeoServer datadir elsewhere
- `GEOWEBCACHE_CONFIG_DIR` to put your GeoServer cache configuration elsewhere
- `GEOWEBCACHE_CACHE_DIR` to put your GeoServer cache elsewhere
- `NETCDF_DATA_DIR` to put your GeoServer NETCDF data dir elsewhere
- `GRIB_CACHE_DIR` to put your GeoServer GRIB cache dir elsewhere

Each of these variables can be associated to an external volume to persist data for example in a docker compose
configuration. More information about this in the section below.

Example of how to build a docker image with just geoserver war and then add plugins at runtime.

```bash
docker build -t geoserver:test-2.19.1 \
--build-arg GIT_HASH=`git show -s --format=%H` \
--build-arg GEOSERVER_WEBAPP_SRC=https://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/geoserver-2.19.1-war.zip/download  .

docker run \
--env PLUGIN_DYNAMIC_URLS="http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/extensions/geoserver-2.19.1-control-flow-plugin.zip \
http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/extensions/geoserver-2.19.1-libjpeg-turbo-plugin.zip" \
--rm --name gs -p 8080:8080 geoserver:test-2.19.1
```


## Using GeoServer with docker-compose
Docker Compose is a tool that helps us easily handle multiple containers at once.

Install instructions: [Docker Docs](https://docs.docker.com/compose/install/)

In order to use Compose we need first to set correctly the "docker-compose.yml" file of the Docker-GeoServer.

### Externalize the data directory of the GeoServer container

In order to persist and externalize access to the data of the geoserver container we need to set the values of the environment variables (named in the previous section) on the container and then associated this to the external volumes we going to create.

To achieve this, first we gonna create a .env file (in the same folder of the docker-compose.yml file) to define in an optimal way (easy to modify later) the environment variables values for the geoserver container:

.env file content:

```bash
GEOSERVER_LOG_DIR=/var/geoserver/logs
GEOSERVER_DATA_DIR=/var/geoserver/datadir
GEOWEBCACHE_CONFIG_DIR=/var/geoserver/datadir/gwc
GEOWEBCACHE_CACHE_DIR=/var/geoserver/gwc_cache_dir
NETCDF_DATA_DIR=/var/geoserver/netcdf_data_dir
GRIB_CACHE_DIR=/var/geoserver/grib_cache_dir
```

More details on the definition of the .env file: [Docker - The Compose Specification](https://github.com/compose-spec/compose-spec/blob/master/spec.md#env_file)

Then we are going to modify the docker-compose configuration file to set environment variables in the geoserver container with the “environment” key:

```yml
...
geoserver:
    build:
      context: .
      dockerfile: ./Dockerfile
    ...
    environment:
      - GEOSERVER_LOG_DIR=${GEOSERVER_LOG_DIR}
      - GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}
      - GEOWEBCACHE_CONFIG_DIR=${GEOWEBCACHE_CONFIG_DIR}
      - GEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR}
      - NETCDF_DATA_DIR=${NETCDF_DATA_DIR}
      - GRIB_CACHE_DIR=${GRIB_CACHE_DIR}
...
```

To be sure that the environment variables are not pass empty, you can set a default value.

Example:
```yml
...
geoserver:
...
    environment:
      - GEOSERVER_LOG_DIR=${GEOSERVER_LOG_DIR:-/var/geoserver/logs}
...
```
If GEOSERVER_LOG_DIR variable is not set in the .env file, is going to take his default value.


Next we are going to define the external volumes, modifying again the docker-compose configuration file.

```yml
services:
...
  geoserver:
    ...
    volumes:
      - logs:${GEOSERVER_LOG_DIR}
      - datadir:${GEOSERVER_DATA_DIR}
      - gwc_config:${GEOWEBCACHE_CONFIG_DIR}
      - gwc:${GEOWEBCACHE_CACHE_DIR}
      - netcfd:${NETCDF_DATA_DIR}
      - grib_cache:${GRIB_CACHE_DIR}
  ...
volumes:
  pg_data:
  logs:
  datadir:
  gwc_config:
  gwc:
  netcfd:
  grib_cache:
```

Both configurations together (environment variables and external volumes) are going to show like this in the docker-compose configuration file:

```yml
services:
...
  geoserver:
    build:
      context: .
      dockerfile: ./Dockerfile
    ...
    environment:
      - GEOSERVER_LOG_DIR=${GEOSERVER_LOG_DIR}
      - GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}
      - GEOWEBCACHE_CONFIG_DIR=${GEOWEBCACHE_CONFIG_DIR}
      - GEOWEBCACHE_CACHE_DIR=${GEOWEBCACHE_CACHE_DIR}
      - NETCDF_DATA_DIR=${NETCDF_DATA_DIR}
      - GRIB_CACHE_DIR=${GRIB_CACHE_DIR}
    volumes:
      - logs:${GEOSERVER_LOG_DIR}
      - datadir:${GEOSERVER_DATA_DIR}
      - gwc_config:${GEOWEBCACHE_CONFIG_DIR}
      - gwc:${GEOWEBCACHE_CACHE_DIR}
      - netcfd:${NETCDF_DATA_DIR}
      - grib_cache:${GRIB_CACHE_DIR}
  ...
volumes:
  pg_data:
  logs:
  datadir:
  gwc_config:
  gwc:
  netcfd:
  grib_cache:
```
After this our geoserver container is ready and persisting his data.

For more details about volumes, check the documentation: [Docker - Volume](https://docs.docker.com/storage/volumes/)

### Using an alternative war file to build GeoServer container of the stack

In the docker-compose.yml file, actually we are building the GeoServer container from a image on a URL.

```yml
...
geoserver:
    build:
      context: .
      dockerfile: ./Dockerfile
      args:
        GEOSERVER_WEBAPP_SRC: "https://build.geoserver.org/geoserver/main/geoserver-main-latest-war.zip"
    container_name: geoserver 
...
```
This is dynamic, you can use a local file in the host to build the container as and alternative if you need. In order to do this, we need to modify the docker-compose configuration file like this:

```yml
...
geoserver:
    build:
      context: .
      dockerfile: ./Dockerfile
      args:
        GEOSERVER_WEBAPP_SRC: "/host/directory/alternativegeoserver.war"
    container_name: geoserver 
...
```

This option allows you to use URLs and local files as well to build the GeoServer container in the option that suit you best.

For more details, check the ADD documentation: [Docker - ADD](https://docs.docker.com/engine/reference/builder/#add)

### Accessing GeoServer postgresql server from outside the container

Containers communicate between themselves in networks created, implicitly or through configuration, by docker compose. To reach a container from the host, the ports must be exposed declaratively through the "ports" keyword, which also allows us to choose if we want exposing the port differently in the host. 

```yml
ports:
- "hostport:containerport" #host:container SHOULD always be specified as a (quoted) string, to avoid conflicts with yaml base-60 float.
```
The Host port and the Container Port can be equal or no, this option allows us to run different containers exposing the same ports without collisions.

GeoServer docker-compose.yml:

```yml
services:
  postgres:
    image: postgis/postgis
    container_name: postgres
    ...
    ports:
      - 5432
    ...

  geoserver:
    ...
    container_name: geoserver
    ...
    ports:
      - 8080
    ...

  proxy:
    image: nginx
    container_name: proxy
    ...
    ports:
    - "80:80"
    ...
```
In this example the only port visible in the host will be port 80 of the proxy container.

In order to access the postgresql server from outside the container, we need to use the "port" option to expose a port.

```yml
services:
  postgres:
    image: postgis/postgis
    container_name: postgres
    ...
    ports:
      - "5432:5432"
    ...
```
To test the expose, we can use "curl" command in the host:

```bash
curl -v localhost:5432

*   Trying 127.0.0.1:5432...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 5432 (#0)
> GET / HTTP/1.1
> Host: localhost:5432
> User-Agent: curl/7.68.0
> Accept: */*
```

More details on expose containers ports: [Docker - The Compose Specification](https://github.com/compose-spec/compose-spec/blob/master/spec.md#ports)

### Starting the containers

When we have everything configured with the docker-compose.yml file, to start the containers for the first time we gonna use this command (located in the directory when the yml file is):

```bash
docker-compose up
```
This is gonna create and start the containers, the networks, and the volumes defined in the docker-compose.yml file. This is the command you need to use every time after a change on the docker-compose.yml file in order to apply the modifications.

After the first time, we can simply use this command to start the containers:

```bash
docker-compose start
```

Console output:

```bash
Starting postgres ... done
Starting geoserver ... done
Starting proxy ... done
...
(Continued with the proxy logs)
```

To stopping all the containers, this is the command:

```bash
docker-compose stop
```

Console output:

```bash
Stopping proxy ... done
Stopping geoserver ... done
Stopping postgres  ... done
```

If you want to reset the status of the containers, we need to run this command, which will destroy everything with only the exception of external volumes:

```bash
docker-compose down
```

## How to build the Docker image with your own geoserver.war file 
 Make sure you have your war file at `./geoserver.war`
 
` docker build --build-arg GEOSERVER_WEBAPP_SRC="./geoserver.war" -t geoserver:test .`

There are [**build arguments**](https://docs.docker.com/engine/reference/commandline/build/) to customize the image:
- `PLUG_IN_URLS` space-separated list of additional plugins for geoserver (see examples), this works both for extensions and community plugins.
- `GEOSERVER_DATA_DIR_SRC` add a customized datadir to the final image. This can be a local zip or directory or remote URL (see [ADD](https://docs.docker.com/engine/reference/builder/#add) documentation)
- `GEOSERVER_WEBAPP_SRC` to add your own custom web app to the final image. This can be a local zip or directory or remote URL (see [ADD](https://docs.docker.com/engine/reference/builder/#add) instruction Doc).
If you want to build or package your own web app you can customize the "mother" stage of Dockerfile accordingly, if you want to download directly GeoServer you may need to add `/download` at the end of download 
url which you can copy/paste from [GeoServer official downloads page](http://geoserver.org/download/), see last example below

### Examples about using Docker image

```bash
# Example of how to build a single customized war of geoserver or simply any vanilla one
docker build -t geoserver:test . --build-arg GEOSERVER_WEBAPP_SRC="./resources/geoserver/geoserver.war"

# Same kind of build as above but burning custom datadir inside GeoServer Docker image

docker build -t geoserver:test . --build-arg GEOSERVER_WEBAPP_SRC="./resources/geoserver/geoserver.war" --build-arg GEOSERVER_DATA_DIR_SRC="./resources/geoserver-datadir/"

# Example on how to download and build a geoserver version with stable plugins controlflow and libjpegturbo plugins burned in the image
docker build -t geoserver:luca-test-2.19.1 --build-arg GEOSERVER_WEBAPP_SRC="https://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/geoserver-2.19.1-war.zip/download" --build-arg PLUG_IN_URLS="http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/extensions/geoserver-2.19.1-control-flow-plugin.zip http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.1/extensions/geoserver-2.19.1-libjpeg-turbo-plugin.zip" .

```

### GeoServer rest reload

While the container is running you can reload geoserver with:

```bash
docker exec -it <your-container-name> bash /usr/local/bin/geoserver-rest-reload.sh
```

### Test plugins on running container

```bash
docker exec -it <your-container-name> bash -c 'geoserver-plugin-download.sh $CATALINA_BASE/webapps/$APP_LOCATION/WEB-INF/lib <space separated list of plugin urls>'
```


## Docker Hub build process and related helper scripts

Scripts provided that are for docker hub are under `hooks` directory.

Basically the `hooks/build` script takes these environment variables with current version numbers offered for geoserver:

```bash
export MAINT_VERSION="2.17.3 2.17.2 2.17.1"
export MIDDLE_STABLE="18"
export NIGHTLY_MAINT_VERSION="2.17.x"
export NIGHTLY_MASTER_VERSION="master foobar"
export NIGHTLY_STABLE_VERSION="2.18.x"
export STABLE_VERSION="2.18.1 2.18.0"
```

Notes:

Phantom version `foobar` is supposed to always fail as a test and always tried to be built.
"MIDDLE_STABLE" has just a function for the scripts logic, increase it with latest minor version number for stable.

To test locally build hook you can use the `test_hooks.sh` script provided.


## How to use `custom_build.sh` script

the script can be run with no parameters to show the needed parameters:

```bash
./custom_build.sh
Usage: ./custom_build.sh [docker image tag] [geoserver version] [geoserver master version] [datadir| nodatadir] [pull|no pull];

[docker image tag] :          the tag to be used for the docker iamge
[geoserver version] :         the release version of geoserver to be used; you can set it to master if you want the last release
[geoserver master version] :  if you use the master version for geoserver you need to set it to the numerical value for the next release;
                              if you use a released version you need to put it to the release number
[datadir| nodatadir]:         if this parameter is equal to nodatadir the datadir is not burned in the docker images
[pull|no pull]:               docker build use always a remote image or a local image
```

This script is meant to be used by automated build, variety of tests with highly customized versions of geoserver.

### Example

```bash
./custom_build.sh my-docker-tag 2.18.x 2.18.x nodatadir no_pull
```

### GIT HASH INFORMATION

This argument provides git hash information from inside of container. In order to get git hash information inside of container add this argument to the build line. As requirement git command should be installed.

--build-arg GIT_HASH=`git show -s --format=%H`

Below command shows git hash information.

docker exec -it <geoserver-container-name>  bash -c 'echo $GIT_HASH'
