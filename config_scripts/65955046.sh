python3 delete_workspace.py admin $GEOSERVER_PWD  PJ_65955046
python3 create_workspace.py admin $GEOSERVER_PWD  PJ_65955046
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 orthos "EPSG:32612"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 orthos ./65955046_orthos.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 orthos orthos
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 PJ_65955046 orthos
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 heatmaps "EPSG:32612"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 heatmaps ./65955046_heatmaps.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 heatmaps heatmaps
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_65955046 PJ_65955046 heatmaps