#!/bin/bash

# executable httpdicom is in the same folder as httpdicom.sh

#$1 OID pacs
#$2 port
#$3 log level (ERROR, INFO, VERBOSE, DEBUG)
#$4 time from Greenwich meridian (+0300)
#$5 path to deploy folder
#$6 path to caché folder for tokens

while true
do
    sleep 5;
    ECHO=`/usr/bin/curl --silent "http://localhost:$2/echo"`;
    if [ "$ECHO" != "echo" ]
    then
        DATE=`date +%Y-%m-%d:%H:%M:%S`;
        printf "\r\n$DATE [ERROR] no echo from $2\r\n";
        killall -c httpdicom;
        sleep 3;
        cmd=$(./httpdicom $1 $2 $3 $4 $5 $6 &)

        ECHO=`/usr/bin/curl --silent "http://localhost:$2/echo"`;
        if [ "$ECHO" == "echo" ]
        then
            printf "successfully restarted\r\n";
        else
            printf "could not restart\r\n";
        fi
    fi
done
