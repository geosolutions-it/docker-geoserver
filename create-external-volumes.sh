#!/bin/bash
docker volume create geoserver_slaves_datadir
docker volume create geoserver_slaves_gwccachedir
docker volume create geoserver_master_datadir
docker volume create geoserver_master_gwccachedir
docker volume create shared_data
docker volume create shared_logs
docker volume create shared_audits
docker volume create gwc_tools
