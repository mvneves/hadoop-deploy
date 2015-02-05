#!/bin/bash
# This scripts generates a tarball with the logs files from each Hadoop node
#

if [ $# -ne 1 ]
then
	echo "Usage: $0 name"
	exit
fi
name=$1

dir=$( cd $(dirname $0) ; pwd -P )
HADOOP_INSTALL_SCRIPTS=$dir/..

source $HADOOP_INSTALL_SCRIPTS/INSTALL.config
source $HADOOP_INSTALL_SCRIPTS/bin/functions/hadoop.sh
source $HADOOP_INSTALL_SCRIPTS/bin/functions/logs.sh

# Load Hadoop environment variables
source $HADOOP_INSTALL_ENV

nodes=`get_nodes`

for i in $nodes
do
	echo $i
	ssh $i tar cf $HADOOP_HOME/hadoop-logs-$i.tar $HADOOP_HOME/logs $HADOOP_HOME/../mapred/local/userlogs # 2>/dev/null
	scp -r $i:$HADOOP_HOME/hadoop-logs-$i.tar /tmp/hadoop-logs-$i.tar
done

d=`date +%Y%m%d%H%M`

dir=/tmp/logs-$d-$name
rm -rf $dir $dir.tgz
mkdir $dir
mv /tmp/hadoop-logs-*.tar $dir

# save iptraf logs
x=`find /tmp/iptraf-log-$name*`
if [ -n "$x" ]
then
	echo $x
	mkdir $dir/iptraf
	cp $x $dir/iptraf
	iptraf_process_logs $dir
else
	echo "iptraf log not found."
fi

# process logs using rumen
#gen_job_history $dir
tar czf $dir.tgz $dir

#rm -fr logs-$d
ls  -l $dir.tgz
cp $dir.tgz .

