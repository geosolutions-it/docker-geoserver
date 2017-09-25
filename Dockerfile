ARG GEOSERVER_BASE_TAG=latest
FROM geosolutionsit/gs-base:${GEOSERVER_BASE_TAG}
MAINTAINER Alessandro Parma<alessandro.parma@geo-solutions.it>

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl
#RUN  ln -s /bin/true /sbin/initctl

# Install updates
RUN apt-get -y update

#------------- Install Utils --------------------------------------------------
RUN apt-get install -y vim zip unzip net-tools telnet

#------------- Cleanup --------------------------------------------------------

# Delete resources after installation
RUN    rm -rf /tmp/resources \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $CATALINA_HOME

ENV TERM xterm

EXPOSE 8080
