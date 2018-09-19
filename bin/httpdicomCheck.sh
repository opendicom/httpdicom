#!/bin/bash

while true
do
    sleep 30;
    ECHO=`/usr/bin/curl --silent http://localhost:11114/echo`;
    if [ "$ECHO" == "echo" ]
    then
        printf '.';
    else
        DATE=`date +%Y-%m-%d:%H:%M:%S`;
        printf "\r\n$DATE [ERROR] no echo from 11114\r\n";
        killall -c httpdicom;
        sleep 3;
        /Users/Shared/httpdicom/bin/httpdicom INFO 11114 /Users/Shared/httpdicom/conf/IRP.plist &

        ECHO=`/usr/bin/curl --silent http://localhost:11114/echo`;
        if [ "$ECHO" == "echo" ]
        then
            printf "successfully restarted\r\n";
        else
            printf "could not restart\r\n";
        fi
    fi
done
