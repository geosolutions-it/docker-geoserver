#!/bin/bash
docker-compose -f ./docker-compose.yml up -d --scale geoserver-slave=2