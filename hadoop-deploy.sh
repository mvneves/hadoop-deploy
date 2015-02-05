#!/bin/bash
# This script configures, installs and starts a Hadoop cluster
#
# Marcelo Veiga Neves <marcelo.veiga@gmail.com>
#

HADOOP_INSTALL_SCRIPTS=$( cd $(dirname $0) ; pwd -P )

# Load script configuration file
source $HADOOP_INSTALL_SCRIPTS/INSTALL.config
source $HADOOP_INSTALL_SCRIPTS/functions/hadoop.sh

if [ -e "$HADOOP_INSTALL_ENV" ]
then
	echo "Previous Hadoop installation found."
	exit
fi

echo "Installing and configuring Hadoop..."
install_start_time=`date +"%s"`
install_hadoop
configure_hadoop
install_stop_time=`date +"%s"`
let install_total_time=$install_stop_time-$install_start_time

echo "Installing and configuring Hadoop..."
startup_start_time=`date +"%s"`
start_hadoop
startup_stop_time=`date +"%s"`
let startup_total_time=$startup_stop_time-$startup_start_time

num_nodes=`get_num_nodes`

echo "Number of nodes: $num_nodes"
echo "Instalation time: $install_total_time"
echo "Startup time: $startup_total_time"
let total_time=$install_total_time+$startup_total_time
echo "Total deploy time: $total_time"

echo
echo "Run:"
echo "source $HADOOP_INSTALL_ENV"


