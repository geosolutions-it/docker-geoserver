ARG BASE_IMAGE_NAME=gs-base
ARG BASE_IMAGE_TAG=latest
FROM geosolutionsit/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}
MAINTAINER Alessandro Parma<alessandro.parma@geo-solutions.it>

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl
#RUN  ln -s /bin/true /sbin/initctl

# Install updates
RUN apt-get -y update

#------------- Install Utils --------------------------------------------------
RUN apt-get install -y vim zip unzip net-tools telnet procps

#------------- Install JPEG Turbo ---------------------------------------------
#ENV jpeg_turbo_version 1.5.3
#RUN wget --no-check-certificate https://downloads.sourceforge.net/project/libjpeg-turbo/${jpeg_turbo_version}/libjpeg-turbo-official_${jpeg_turbo_version}_amd64.deb \
# && dpkg -i ./libjpeg*.deb \
# && apt-get -f install

#------------- Cleanup --------------------------------------------------------

# Delete resources after installation
RUN    rm -rf /tmp/resources \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $CATALINA_HOME

ENV TERM xterm

EXPOSE 8080
