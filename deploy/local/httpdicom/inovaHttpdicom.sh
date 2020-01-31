#!/bin/bash

while true
do
    sleep 5;
    ECHO=`/usr/bin/curl --silent http://localhost:11114/echo`;
    if [ "$ECHO" == "echo" ]
    then
        printf '.';
    else
        DATE=`date +%Y-%m-%d:%H:%M:%S`;
        printf "\r\n$DATE [ERROR] no echo from 11114\r\n";
        killall -c httpdicom;
        sleep 3;
        /Volumes/GITHUB/httpdicom/deploy/local/httpdicom/httpdicom 1.3.6.1.4.1.23650.152.0.2.1229868886.1 11114 INFO +0300 /Volumes/GITHUB/httpdicom/deploy /Volumes/TMP &

        ECHO=`/usr/bin/curl --silent http://localhost:11114/echo`;
        if [ "$ECHO" == "echo" ]
        then
            printf "successfully restarted\r\n";
        else
            printf "could not restart\r\n";
        fi
    fi
done
