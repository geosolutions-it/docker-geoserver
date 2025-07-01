# docker-geoserver

Run geoserver within docker.

Based on the official tomcat docker image, specifically:
- Tomcat 9
- JDK 11 (eclipse temurin)
- Ubuntu Jammy (22.04 LTS)

## Build the Docker image

Clone this docker-geoserver branch.

Download the necessary plugins.

```
pushd resources/geoserver-plugins
wget 'https://build.geoserver.org/geoserver/2.27.x/community-latest/geoserver-2.27-SNAPSHOT-opensearch-eo-plugin.zip'
wget 'https://sourceforge.net/projects/geoserver/files/GeoServer/2.27.1/extensions/geoserver-2.27.1-control-flow-plugin.zip'
wget 'https://sourceforge.net/projects/geoserver/files/GeoServer/2.27.1/extensions/geoserver-2.27.1-jp2k-plugin.zip'
wget 'https://sourceforge.net/projects/geoserver/files/GeoServer/2.27.1/extensions/geoserver-2.27.1-monitor-plugin.zip'
popd
```

Download the WAR file.

```
wget 'https://sourceforge.net/projects/geoserver/files/GeoServer/2.27.1/geoserver-2.27.1-war.zip'
unzip geoserver-2.27.1-war.zip geoserver.war
```

Build the image.  
Replace the image tag (`-t`) with whatever fits your needs.

```
docker build \
    -t geosolutionsit/geoserver:C134-2.27.1 \
    --build-arg GEOSERVER_WEBAPP_SRC="./geoserver.war" \
    --build-arg PLUG_IN_PATHS="./resources/geoserver-plugins/" \
    .
```

Test the image running a temporary container.

```
docker run --rm -it -p8080:8080 --name gs geosolutionsit/geoserver:C134-2.27.1
```
