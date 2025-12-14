#!/bin/bash
RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
NC='\e[0m' # No Color (resets to default)

echo "${BLUE}Updating apt.${NC}"
apt update && apt upgrade -y

echo "${BLUE}Installing authbind.${NC}"
apt-get install authbind
cd /etc/authbind
touch /etc/authbind/byport/80
chown debian:debian /etc/authbind/byport/80
echo "${BLUE}Stopping nginx if running${NC}"
systemctl stop nginx
systemctl disable nginx

echo "${BLUE}Installing essential libraries to run modbus app${NC}"
apt-get -y build-essential libmodbus-dev  libcjson-dev libsqlite3-dev libhiredis-dev python3-venv python3-pip

cd modbus
runuser -l debian -c "gcc -o  modbus_to_redis  modbus_to_redis.c config.c -lmodbus -lcjson -lsqlite3 -lhiredis"


#must reboot
#sudo reboot now


#cd webserver
 
#runuser -l debian -c 





