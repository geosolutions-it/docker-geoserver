#!/bin/bash
#
################################################################################
# This script allows to call the masstruncate functionality of GeoWebCache for 
# all the layers that match specific regex for a cluster of GeoServer instances.
# Usage: 
# cleancache.sh regex
# e.g. 
# cleancache.sh "^topp\\:"
# cleancache.sh "^topp\\:states$"
# If regex not present use the standard input to get a list of layers to 
# clear. Redirect a file or write the list and then type CTRL+D to start
################################################################################
#
# author: Lorenzo Natali - lorenzo.natali@geo-solutions.it
# 
# Copyright 2015, GeoSolutions Sas.
# All rights reserved.
# 
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
# 
################################################################################
 
#GEOSERVER ADMINISTRATOR CREDENTIALS
USER="admin"
PASSWORD="geoserver"

# Array of geoserver instances
GEOSERVER_INSTANCES=("http://172.17.0.1:8080/master/gwc/rest/" "http://172.17.0.1:80/geoserver/gwc/rest/")
# For UNAVCO uncomment following line
# GEOSERVER_INSTANCES=("http://geoserver1.int.unavco.org:8080/master/gwc/rest/ http://geoserver1.int.unavco.org:80/geoserver/gwc/rest/")

# Use the rest URL of the first instance is the default one
GWCRESTURL=${GEOSERVER_INSTANCES[0]};

#THE REGEX TO PARSE
# e.g. 
# "^topp\\:" All layers for topp workspace
# "^topp\\:states$" The layer topp:states
REGEX="$1"

#HEADERS
CTYPE="Content-type: text/xml, application/x-www-form-urlencoded"
H_ACCEPT="Accept: text/xml"

#LAYER LIST SERVICE 
GWCLISTURL="${GWCRESTURL}layers.xml"
progname="$0"
echo "*************************************************************************"
echo "**** GEOWEBCACHE CLEAN TOOL *********************************************"
echo "*************************************************************************"
echo "This tool helps to do a full tile cache clean (called Mass Truncate) for "
echo "a group of layers identified by a regex passed as argument. "
echo "if the regex is not passed as argument the script will use the standard"
echo "input."
echo 
echo "* Usage 1 (regex) * "
echo "$progname regex"
echo 
echo "* Usage 2 (standard input from file) *" 
echo "cat layerlist.txt | $progname"
echo 
echo "* Usage 3 (standard input):  $progname *"
echo "layer1"
echo "layer2"
echo "CTRL+D"
echo 
echo "Quering layers to truncate at :"
echo "   ${GWCLISTURL}"
echo "*************************************************************************"


################################################################################
# clear_layers()
# Uses the GeoServer REST interface to clear cache to many GeoServer cluster 
# instances
################################################################################
clear_layers(){
    layers=$1
    width=30
    max=$(( ${#GEOSERVER_INSTANCES[@]} * ${#layers[@]} ))
    bar_char="#"
    for (( i=0; i<${#layers[@]}; i++ ));
    do 
        layer=${layers[i]};
        for (( j=0; j<${#GEOSERVER_INSTANCES[@]}; j++ ));
        do 
            geoserver_url=${GEOSERVER_INSTANCES[j]};
            
            # Progress bar
            index=$(( i * ${#GEOSERVER_INSTANCES[@]} + j + 1))
            perc=$(( index * 100 / max ))
            num=$((index * width / max ))
            if [ $num -gt 0 ]; then
                bar=$(printf "%0.s${bar_char}" $(seq 1 $num))
            fi
            line=$(printf "[%-${width}s] (%d%%) %s" "$bar" "$perc" "$layer - server[$((j+1))/${#GEOSERVER_INSTANCES[@]}]" )
            endl="\e[0K\r"
            echo -ne "$endl $line"
            
            # cache clean
            ./gwc.sh masstruncate -u "$geoserver_url" -a "$USER:$PASSWORD" "${layer}" &>  /dev/null
        done;
    done;
echo 
echo "*************************************************************************"
echo "cache clean finished"
echo "*************************************************************************"
}
################################################################################
# display_layers()
# Show the list of layers found using the regex
################################################################################
display_layers(){
    layers=$1
    for (( i=0; i<${#layers[@]}; i++ ));
    do 
        echo "  ${layers[i]}"
    done
}


################################################################################
# SCRIPT START
################################################################################

# test if argument passed
if [ $# -le 0 ]; then 
    # Not interactive mode read from stdin the layers
    while read line
    do
        layers=("${layers[@]}" $line)
    done
echo "*************************************************************************"
echo " Layers To Empty "
echo "*************************************************************************"
    display_layers $layers
echo "*************************************************************************"
    clear_layers $layers
    exit
fi

# Filter with regex
echo "*************************************************************************"
echo "Fitler with REGEX:"
echo "   ${REGEX}"
echo "*************************************************************************"
# Get the list of layers from GeoServer
# NOTE: because of this issue: http://sourceforge.net/p/xmlstar/bugs/54/
# we use "-m query -v ." instead of "-v query" as suggested here : http://sourceforge.net/p/xmlstar/bugs/54/#e70c
layers=( $(curl -s -u "${USER}:${PASSWORD}" "${GWCLISTURL}"  -H  "${CTYPE}" | xmlstarlet sel  -t -m  "layers/layer/name" -v . -n | grep "${REGEX}" ) )
echo "${#layers[@]} layers found:"
display_layers $layers  

#CONFIRM TRUNCATE
read -r -p "Do you want to clear cache for these layers? (y/n) " REPLY
if [[ $REPLY =~ ^[Yy]$ ]]
then
    clear_layers $layers
    echo "END OF CACHE CLEAN"
else 
    echo "Exiting..."
fi