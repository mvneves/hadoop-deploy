#!/bin/bash
# This script uninstalls Hadoop and cleans up the temporary directories
#
# Marcelo Veiga Neves <marcelo.veiga@gmail.com>
#

HADOOP_INSTALL_SCRIPTS=$( cd $(dirname $0) ; pwd -P )

# Load script configuration file
source $HADOOP_INSTALL_SCRIPTS/INSTALL.config

source $HADOOP_INSTALL_SCRIPTS/functions/hadoop.sh

if [ ! -e "$HADOOP_INSTALL_ENV" ]
then
	echo "Existing Hadoop installation not found."
	exit
fi

echo "Stopping Hadoop..."
stop_start_time=`date +"%s"`
stop_hadoop
stop_stop_time=`date +"%s"`
let stop_total_time=$stop_stop_time-$stop_start_time

echo "Cleaning up Hadoop files..."
cleanup_start_time=`date +"%s"`
cleanup_tmp
cleanup_stop_time=`date +"%s"`
let cleanup_total_time=$cleanup_stop_time-$cleanup_start_time

num_slaves=`cat $HADOOP_INSTALL_SCRIPTS/tmp/slaves | wc -l`

echo "Number of nodes: $num_nodes"
echo "Stopping time: $stop_total_time"
echo "Cleaning up time: $cleanup_total_time"
let total_time=$stop_total_time+$cleanup_total_time
echo "Total shutdown time: $total_time"

