#!/bin/bash
GITUSERNAME=youruser
GITPASSWORD=yourpassword
CATALOGREPO=yourcatalogrepo  #example: github.com/jemacchi/unavco-catalog.git
# push master changes from volume to repo
cd /var/geoserver/volumes/geoserver_master/datadir
sudo git add *
sudo git commit --allow-empty-message -m ""
sudo git push https://$GITUSERNAME:$GITPASSWORD@$CATALOGREPO
# pull master changes on slaves volume
cd /var/geoserver/volumes/geoserver_slaves/datadir
sudo git reset --hard origin/main
sudo git pull https://$GITUSERNAME:$GITPASSWORD@$CATALOGREPO
# restart slaves (one by one)
sudo docker ps -aqf "name=^.*geoserver-slave_.*$" | while read line; do echo 'Restarting geoserver slave container : '$line; sudo docker restart $line; done