#!/bin/sh
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
        ENA=`tail -n 1 ${PORTS_DIR}${port} | awk '{print $2}'`
        if [ ${ENA} -eq 1 ]; then
            if [ ! -f ${PORTS_DIR}${port}.limit ]; then
                LIMITS=`tail -n 1 ${PORTS_DIR}${port} | awk '{print $3}'`
                echo $LIMITS
                USAGE=`iptables -n -v -L -t filter | grep -i "spt:$port" | awk -F' ' '{print $2}'`
                if [ $? -eq 0 ]; then
                    USAGE=`echo ${USAGE} | tr -d 'M'`
                    if [ ${USAGE} -gt ${LIMITS} ]; then
                        sed -i.bak 's/^\(\s\+\)\(\"'"${port}"'\"\)/#\1\2/' ${CONFIG_FILE}
                        ${DEBUGEXEC} iptables -D OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}
                        RELOAD=1
                        touch ${PORTS_DIR}${port}.limit
                    fi
                fi
            fi
        fi
    done
fi

if [ ${RELOAD} -eq 1 ]; then
    ${DEBUGEXEC} supervisorctl reload
fi

