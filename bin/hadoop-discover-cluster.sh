#!/bin/bash
# This script discovers the cluster nodes (using PBS/Torque node file) 
# and their IP addresses. It also prepares masters/slaves files for Hadoop.
#
# Marcelo Veiga Neves <marcelo.veiga@gmail.com>
#

dir=$( cd $(dirname $0) ; pwd -P )
HADOOP_INSTALL_SCRIPTS=$dir/..

source $HADOOP_INSTALL_SCRIPTS/INSTALL.config


if [ -e "$PBS_NODEFILE" ]
then
	cat $PBS_NODEFILE | sort | uniq > machines.txt
else
	echo "Cluster not allocated. \$PBS_NODEFILE is empty."
	echo "Using nodes from machines.txt file instead." #" [press ENTER to continue] "
	#read
fi

if [ ! -e "./machines.txt" ]
then
	if [ ! -e "$HADOOP_INSTALL_SCRIPTS/machines.txt" ]
	then
		echo "machines.txt file not found."
		exit 1
	else
		cp $HADOOP_INSTALL_SCRIPTS/machines.txt ./machines.txt
	fi
fi

source $HADOOP_INSTALL_SCRIPTS/bin/functions/pbs_utils.sh

slaves=`cat ./machines.txt | sort | uniq`

# discover master IP
master=`/sbin/ifconfig $HADOOP_INSTALL_IFACE | grep "inet addr:" | sed -r 's/.*inet addr:([0-9.]+).*/\1/g'`

# remove data from previous installation
rm -f $HADOOP_INSTALL_SCRIPTS/tmp/masters
rm -f $HADOOP_INSTALL_SCRIPTS/tmp/slaves
rm -f $HADOOP_INSTALL_SCRIPTS/tmp/mapslots

# create master file
echo "masters:"
echo " $master"
echo $master >> $HADOOP_INSTALL_SCRIPTS/tmp/masters

# create slaves file
rm -f $HADOOP_INSTALL_SCRIPTS/tmp/slaves
echo "slaves:"
for node in $slaves
do
	ip=`ssh $node /sbin/ifconfig $HADOOP_INSTALL_IFACE | grep "inet addr:" | sed -r 's/.*inet addr:([0-9.]+).*/\1/g'`
	echo " $ip"
	echo $ip >> $HADOOP_INSTALL_SCRIPTS/tmp/slaves
done

if [ -e "$PBS_NODEFILE" ]
then
	cores=`pbs_ppn`
else
	cores=`cat /proc/cpuinfo | grep processor | wc -l`
fi
echo $cores > $HADOOP_INSTALL_SCRIPTS/tmp/taskslots

