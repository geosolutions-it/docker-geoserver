#!/usr/bin/env bash
set -m
catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
