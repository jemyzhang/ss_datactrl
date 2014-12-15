#!/bin/bash

SERVER_IP=`curl ip.cn | awk -F' ' '{print $2}' | sed 's/IP：//g'`

CONFIG_FILE=/etc/shadowsocks.json

DATA_CONFIG_DIR=/root/datactrl
PORTS_DIR=${DATA_CONFIG_DIR}/ports/
DATA_DIR=${DATA_CONFIG_DIR}/data/

#DEBUGEXEC=echo

