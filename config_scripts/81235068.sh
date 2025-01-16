python3 delete_workspace.py admin $GEOSERVER_PWD  PJ_81235068
python3 create_workspace.py admin $GEOSERVER_PWD  PJ_81235068
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 orthos "EPSG:32611"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 orthos ./81235068_orthos.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 orthos orthos
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 PJ_81235068 orthos
python3 create_mosaic.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 heatmaps "EPSG:32611"
python3 harvest_cog.py  "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 heatmaps ./81235068_heatmaps.txt
python3 create_coverage.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 heatmaps heatmaps
python3 create_vector.py "http://localhost:8080/geoserver" admin $GEOSERVER_PWD  PJ_81235068 PJ_81235068 heatmaps