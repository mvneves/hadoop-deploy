#!/bin/sh

pids=`ps auxf | grep java | grep $USER | awk '{print $2}'`

if [ ! -z "$pids" ]
then
	echo "Killing $pids"
	kill -9 $pids
fi

