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
if [ $# -gt 0 ]; then
    NO_CHECK_EXPIRE=1
fi

if [ -d ${PORTS_DIR} ]; then
    for port in `ls ${PORTS_DIR}`
    do
        if [ $NO_CHECK_EXPIRE -eq 1 ]; then
            echo "no check expire"
        else
            EXPIRE=`cat ${PORTS_DIR}${port} | grep valid_days | sed 's/valid_days=\(.*\)/\1/'`
            if [ $EXPIRE -le 0 ]; then
                sed -i.bak 's/enabled=1/enabled=0/' ${PORTS_DIR}${port}
                rm -f ${PORTS_DIR}*.bak
            else
                let left_days=EXPIRE-1
                sed -i.bak 's/valid_days='"$EXPIRE"'/valid_days='"$left_days"'/' ${PORTS_DIR}${port}
                rm -f ${PORTS_DIR}*.bak
            fi
        fi
        ENA=`cat ${PORTS_DIR}${port} | grep enabled | sed 's/enabled=\(.*\)/\1/'`
        if [ ${ENA} -eq 0 ]; then
            sed -i.bak 's/^\(\s\+\)\(\"'"${port}"'\"\)/#\1\2/' ${CONFIG_FILE}
            #reset data counter
            ${DEBUGEXEC} /sbin/iptables -D OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}
        else
            sed -i.bak 's/^#\(\s\+\)\(\"'"${port}"'\"\)/\1\2/' ${CONFIG_FILE}

            #record data count
            USAGE=`/sbin/iptables -n -v -L -t filter | grep -i "spt:$port" | awk -F' ' '{print $2}'`
            if [ ! -d ${DATA_DIR}${port} ]; then
                mkdir ${DATA_DIR}
            fi
            echo "`date "+%Y%m%d"` ${USAGE}" >> ${DATA_DIR}${port}

            #reset data counter
            ${DEBUGEXEC} /sbin/iptables -D OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}

            #start data counter
            ${DEBUGEXEC} /sbin/iptables -I OUTPUT -s ${SERVER_IP} -p tcp --sport ${port}
            if [ -f ${PORTS_DIR}${port}.limit ]; then
                #restart limit checking
                rm -f ${PORTS_DIR}${port}.limit
            fi
        fi
    done
fi

${DEBUGEXEC} supervisorctl reload
