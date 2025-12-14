#!/bin/bash
apt update && apt upgrade -y


apt-get install authbind
cd /etc/authbind
touch /etc/authbind/byport/80
chown debian:debian /etc/authbind/byport/80
systemctl stop nginx
systemctl disable nginx

apt-get -y build-essential libmodbus-dev  libcjson-dev libsqlite3-dev libhiredis-dev python3-venv python3-pip

runuser -l debian -c "git clone https://github.com/saifuhameed/iot-bare-stack.git"

cd modbus 
runuser -l debian -c "gcc -o  modbus_to_redis  modbus_to_redis.c config.c -lmodbus -lcjson -lsqlite3 -lhiredis"

#must reboot
#sudo reboot now


#cd webserver
 
#runuser -l debian -c 





