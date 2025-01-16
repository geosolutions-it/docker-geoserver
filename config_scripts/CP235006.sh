python3 delete_workspace.py admin $GEOSERVER_PWD  CP235006
python3 create_workspace.py admin $GEOSERVER_PWD  CP235006
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 orthos "EPSG:3857"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 orthos ./CP235006_orthos.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 orthos orthos
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 CP235006 orthos
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 heatmaps "EPSG:3857"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 heatmaps ./CP235006_heatmaps.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 heatmaps heatmaps
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  CP235006 CP235006 heatmaps