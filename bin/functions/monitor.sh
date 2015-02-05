#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: $0 start|stop|status"
	exit
fi

iface=$2

##############################################################################
## iptraf - network traffic monitor
##############################################################################

ip=`/sbin/ifconfig $iface | grep "inet addr:" | sed -r 's/.*inet addr:([0-9.]+).*/\1/g'`

iptraf_log="/tmp/iptraf-log-$ip.txt"

start_iptraf()
{
	sudo rm -f /tmp/iptraf-log-*
	sudo iptraf -L $iptraf_log -i $iface -B
}

stop_iptraf()
{
	sudo killall -s SIGUSR2 iptraf
	sudo chown $USER $iptraf_log
}

status_iptraf()
{
	x=`/sbin/pidof iptraf`
	if [ -n "$x" ]
	then
		echo "iptraf is running ($x)"
	else
		echo "iptraf is not running"
	fi
}

##############################################################################


case "$1" in

start)
	echo "Starting monitor..."
	start_iptraf
	;;
stop)
	echo "Stopping monitor..."
	stop_iptraf
	;;
status)
	echo "Status:"
	status_iptraf
	;;
*) echo "Invalid option!"
   ;;
esac
