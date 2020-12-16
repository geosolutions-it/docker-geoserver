#!/bin/bash
GITUSERNAME=youruser
GITPASSWORD=yourpassword
CATALOGREPO=yourcatalogrepo  #example: github.com/jemacchi/unavco-catalog.git
# push backoffice changes from volume to repo
cd /var/geoserver/volumes/geoserver_master/datadir
sudo git add *
sudo git commit --allow-empty-message -m ""
sudo git push https://$GITUSERNAME:$GITPASSWORD@$CATALOGREPO
# pull backoffice changes on prod volume
cd /var/geoserver/volumes/geoserver_slaves/datadir
sudo git reset --hard origin/main
sudo git pull https://$GITUSERNAME:$GITPASSWORD@$CATALOGREPO
# restart instances (one by one)
sudo docker ps -aqf "name=^.*geoserver-slave_.*$" | while read line; do echo 'Restarting geoserver slave container : '$line; sudo docker restart $line; until [ "`sudo docker inspect -f {{.State.Running}} $line`"=="true" ]; do sleep 1; done; done
