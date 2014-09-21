#!/bin/bash
if [ -h $0 ]; then
    execpath=`dirname $0`"/"`readlink $0`
else
    execpath=$0
fi
    
dirname=`dirname $execpath`
tmp="${dirname#?}"
if [ "${dirname%$tmp}" != "/" ]; then
dirname=$PWD/$dirname
fi

if [ ! -f ${dirname}/config.sh ]; then
    echo "failed to found config file"
    exit 1
fi

. ${dirname}/config.sh

RELOAD=0
if [ -d ${PORTS_DIR} ]; then
    for port in `ls ${PORTS_DIR}`
    do
        ENA=`cat ${PORTS_DIR}${port} | grep enabled | sed 's/enabled=\(.*\)/\1/'`
        if [ ${ENA} -eq 0 ]; then
            continue
        fi

        CTRL=`cat ${PORTS_DIR}${port} | grep limit_ctrl | sed 's/limit_ctrl=\(.*\)/\1/'`
        if [ ${CTRL} -eq 0 ]; then
            continue
        fi

        if [ -f ${PORTS_DIR}${port}.limit ]; then
            continue
        fi

        LIMITS=`cat ${PORTS_DIR}${port} | grep data_limit | sed 's/data_limit=\(.*\)/\1/'`
        USAGE=`/sbin/iptables -n -v -L -t filter | grep -i "spt:$port" | awk -F' ' '{print $2}'` | grep 'M'
        if [ $? -eq 0 ]; then
            USAGE=`echo ${USAGE} | tr -d 'M'`
            if [ ${USAGE} -gt ${LIMITS} ]; then
                sed -i.bak 's/^\(\s\+\)\(\"'"${port}"'\"\)/#\1\2/' ${CONFIG_FILE}
                ${DEBUGEXEC} /sbin/iptables -D OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}
                RELOAD=1
                touch ${PORTS_DIR}${port}.limit
            fi
        fi
    done
fi

if [ ${RELOAD} -eq 1 ]; then
    ${DEBUGEXEC} supervisorctl reload
fi

