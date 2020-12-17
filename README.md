# docker-geoserver

## How to run it
Pull the image from [Docker Hub](https://hub.docker.com/r/geosolutionsit/geoserver/)

`docker pull geosolutionsit/geoserver`

And run it

`docker run --name gs -p 8080:8080 geosolutionsit/geoserver`

Open your browser and point it to `http://localhost:8080/geoserver` . 
GeoServer web interface will show up, you can now log in with user admin and password `geoserver`.

There are some [**environment variables**](https://docs.docker.com/engine/reference/run/) you can use at run time:
- `JAVA_OPTS` to customize JAVA_OPTS for the container


## How to build it
If you want to build the image by yourself just run `docker build` from the root of the repository

` docker build -t geoserver:test .`

There are [**build arguments**](https://docs.docker.com/engine/reference/commandline/build/) to customize the image:
- `GEOSERVER_DATA_DIR_SRC` to add your own custom datadir to the final image. This can be a local tar or directory or remote URL (see [ADD](https://docs.docker.com/engine/reference/builder/#add) instruction Doc)
- `GEOSERVER_WEBAPP_SRC` to add your own custom web app to the final image. This can be a local tar or directory or remote URL (see [ADD](https://docs.docker.com/engine/reference/builder/#add) instruction Doc)

If you want to build or package your own web app you can customize the "mother" stage of Dockerfile accordingly
