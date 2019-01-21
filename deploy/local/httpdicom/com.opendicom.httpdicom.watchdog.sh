#!/bin/bash

while true
do
    sleep 30;
    ECHO=`/usr/bin/curl --silent http://localhost:11124/echo`;
    if [ "$ECHO" == "echo" ]
    then
        printf '.';
    else
        DATE=`date +%Y-%m-%d:%H:%M:%S`;
        printf "\r\n$DATE [ERROR] no echo from 11114\r\n";
        killall -c httpdicom;
        sleep 3;
        /Users/Shared/local/httpdicom/httpdicom 1.3.6.1.4.1.23650.152.0.2.737765846967 11124 DEBUG +0300 &
        sleep 10;
        ECHO=`/usr/bin/curl --silent http://localhost:11114/echo`;
        if [ "$ECHO" == "echo" ]
        then
            printf "successfully restarted\r\n";
        else
            printf "could not restart\r\n";
        fi
    fi
done
