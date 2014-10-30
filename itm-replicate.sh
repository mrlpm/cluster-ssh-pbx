#!/bin/bash

source /etc/pbx-ha.conf

intervalo=3
max=$[ $minutos * 60 / $intervalo ]
contador=0

function exesync(){
    echo "ejecutando sincronizacion"
    ssh -p 8756 -i /SSH/asterisk/.ssh/id_rsa "${user}@${PBX02}" /usr/local/sbin/sync.sh
}

function slavealive() {
    if [ $HOSTNAME == "${PBX01}" ]
    then
        ping -c 2 ${IP1} > /dev/null 2>&1
        if [ $? == 0 ]
        then
            return 0
        else
            return 1
        fi
    else
        ping -c 2 ${IP2} > /dev/null 2>&1
        if [ $? == 0 ]
        then
            return 0
        else
            return 1
        fi
    fi
}

function verifyvip() {
IP=$(hostname -I |grep -o ${VIP})
if [[ -z "${IP}" ]]
    then
        return 1
    else
        return 0
fi
}

while true 
do
verifyvip
if [ $? == 0 ]
then 
    restante=$[ ($max - $contador) * $intervalo  ]
    echo "soy master"
    slavealive 
    if [ $? == 0 ]
    then
        echo "Faltan $restante segundos para sincronizar"
        if [ ${contador} == ${max} ]
        then
            exesync
            contador=0
            restante=0
        else
            if [ "$FLAG" == "UNREACHABLE" ]
            then
                echo "SLAVE JUST COME UP"
                exesync
                contador=0
                restante=0
            fi
            FLAG="REACHABLE"
        fi
    else
           echo "slave inalcanzable" 
           FLAG="UNREACHABLE"
    fi
else
    echo "soy slave"
fi
contador=$[ $contador + 1 ]
sleep 3
done
