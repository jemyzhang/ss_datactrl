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

if [ -d ${PORTS_DIR} ]; then
    for port in `ls ${PORTS_DIR}`
    do
        #record data count
        USAGE=`iptables -n -v -L -t filter | grep -i "spt:$port" | awk -F' ' '{print $2}'`
        echo "`date "+%Y%m%d" ${USAGE}" > ${DATA_DIR}${port}

        #reset data counter
        ${DEBUGEXEC} iptables -D OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}

        ENA=`tail -n 1 ${PORTS_DIR}${port} | awk '{print $1}'`
        if [ ${ENA} -eq 0 ]; then
            sed -i.bak 's/^\(\s\+\)\(\"'"${port}"'\"\)/#\1\2/' ${CONFIG_FILE}
        else
            sed -i.bak 's/^#\(\s\+\)\(\"'"${port}"'\"\)/\1\2/' ${CONFIG_FILE}

            #start data counter
            ${DEBUGEXEC} iptables -I OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}
            if [ -f ${PORTS_DIR}${port}.limit ]; then
                #restart limit checking
                rm -f ${PORTS_DIR}${port}.limit
            fi
        fi
    done
fi

${DEBUGEXEC} supervisorctl reload
