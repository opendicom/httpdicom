#!/bin/bash

ECHO=`/usr/bin/curl --silent http://localhost:11111/echo`;
if [ "$ECHO" == "echo" ]
then
    printf '.';
else
    DATE=`date +%Y-%m-%d:%H:%M:%S`;
    printf "\r\n$DATE [ERROR] no echo from 11111\r\n";
#killall -c httpdicom;
#    /Users/Shared/httpdicom/bin/httpdicom INFO 11111 /Users/Shared/httpdicom/conf/SONO+CHP.plist;
    ECHO=`/usr/bin/curl --silent http://localhost:11111/echo`;
    if [ "$ECHO" == "echo" ]
    then
        printf "successfully restarted\r\n";
    else
        printf "could not restart\r\n";
    fi
fi
