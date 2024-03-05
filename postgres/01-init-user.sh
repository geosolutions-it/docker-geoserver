#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username ${POSTGRES_USER} --dbname ${POSTGRES_DB} <<-EOSQL
    CREATE USER geoserver WITH LOGIN PASSWORD 'geoserver';
    CREATE DATABASE geoserver;
    \c geoserver
    CREATE EXTENSION postgis;
    GRANT ALL PRIVILEGES ON DATABASE geoserver TO geoserver;
    CREATE DATABASE "gwc_quota" WITH OWNER "geoserver";
EOSQL
