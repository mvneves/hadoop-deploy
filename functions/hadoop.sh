HADOOP_INSTALL_SCRIPTS=$( cd $(dirname $0) ; pwd -P )
source $HADOOP_INSTALL_SCRIPTS/INSTALL.config
source $HADOOP_INSTALL_SCRIPTS/functions/pbs_utils.sh
source $HADOOP_INSTALL_SCRIPTS/functions/network.sh

HADOOP_BASE="$HADOOP_INSTALL_DEST/hadoop-$USER"
HADOOP_HOME="$HADOOP_BASE/hadoop"

get_version()
{
	name=$1
	major=`echo $name | sed 's/hadoop-\([0-9]*\).*/\1/g'`
	minor=`echo $name | sed 's/hadoop-[0-9]*.\([0-9]*\).*/\1/g'`
	rev=`echo $name | sed 's/hadoop-[0-9]*.[0-9]*.\([0-9]*\).*/\1/g'`
	#echo "Version: $major.$minor.$rev"
	echo $major
}

get_master()
{
	head -n 1 $HADOOP_INSTALL_SCRIPTS/tmp/masters
}

get_slaves()
{
	cat $HADOOP_INSTALL_SCRIPTS/tmp/slaves
}

get_nodes()
{
	cat $HADOOP_INSTALL_SCRIPTS/tmp/slaves $HADOOP_INSTALL_SCRIPTS/tmp/masters | sort | uniq
}

get_num_nodes()
{
	get_nodes | wc -l
}

prepapre_hadoop_configuration()
{
	node=$1
	master=`get_master`
	local_address=`get_remote_address $node $HADOOP_INSTALL_IFACE`

	echo "Preparing config files for $local_address ..."

	# create core site file
	tmpdir=`echo $HADOOP_INSTALL_DEST | awk 'gsub( /\// , "\\\/" ,$0 )'`
	cat $HADOOP_INSTALL_SCRIPTS/templates/core-site.xml | sed "s/MACHINE/$master/g" | \
	sed "s/TMPDIR/$tmpdir/g" > \
	$HADOOP_INSTALL_SCRIPTS/tmp/core-site.xml
	echo $HADOOP_INSTALL_SCRIPTS/tmp/core-site.xml

	# create hdfs conf file
	cat $HADOOP_INSTALL_SCRIPTS/templates/hdfs-site.xml | sed "s/LOCAL_ADDRESS/$local_address/g" > \
	$HADOOP_INSTALL_SCRIPTS/tmp/hdfs-site.xml
	echo $HADOOP_INSTALL_SCRIPTS/tmp/hdfs-site.xml

	# create mapred site file
	cat $HADOOP_INSTALL_SCRIPTS/templates/mapred-site.xml | sed "s/MACHINE/$master/g" | \
	sed "s/TMPDIR/$tmpdir/g" | \
	sed "s/LOCAL_ADDRESS/$local_address/g" > \
	$HADOOP_INSTALL_SCRIPTS/tmp/mapred-site.xml
	echo $HADOOP_INSTALL_SCRIPTS/tmp/mapred-site.xml

	# create hadoop env file
	cat $HADOOP_INSTALL_SCRIPTS/templates/hadoop-env.sh | \
	sed 's!^# export JAVA_HOME.*!export JAVA_HOME='"$HADOOP_INSTALL_JAVA"'!g' > \
	$HADOOP_INSTALL_SCRIPTS/tmp/hadoop-env.sh
	echo $HADOOP_INSTALL_SCRIPTS/tmp/hadoop-env.sh

	# create log config file
	cp $HADOOP_INSTALL_SCRIPTS/templates/log4j.properties $HADOOP_INSTALL_SCRIPTS/tmp/

	# check results
	echo "Checking hadoop env:"
	grep 'JAVA_HOME=' $HADOOP_INSTALL_SCRIPTS/tmp/hadoop-env.sh 

	# create hadoop config env file
	hadoop_config_env=$HADOOP_INSTALL_SCRIPTS/tmp/HADOOP.config

	tarball=`basename $HADOOP_INSTALL_TARBALL`
	hadoop_version=`echo $tarball | sed -r 's/hadoop-(.*).tar.gz$/\1/'`

	echo export HADOOP_HOME=$HADOOP_HOME | tee $hadoop_config_env
	echo export HADOOP_VERSION=$hadoop_version | tee -a $hadoop_config_env
	echo export JAVA_HOME=$HADOOP_INSTALL_JAVA | tee -a $hadoop_config_env
	echo export PATH=\$HADOOP_HOME/bin:\$JAVA_HOME/bin:\$PATH | tee -a $hadoop_config_env
	echo $hadoop_config_env
 }

configure_hadoop()
{
	allnodes=`get_nodes`

	# copy config files to nodes
	echo "Copying config files to nodes:"
	for node in $allnodes
	do
		echo $node
		prepapre_hadoop_configuration $node
		scp $hadoop_config_env $node:$HADOOP_HOME/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/core-site.xml $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/mapred-site.xml $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/hdfs-site.xml $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/hadoop-env.sh $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/masters $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/slaves $node:$HADOOP_HOME/conf/
		scp $HADOOP_INSTALL_SCRIPTS/tmp/log4j.properties $node:$HADOOP_HOME/conf/
	done
 }




install_hadoop()
{
	slaves=`get_nodes`

	echo "Preparing Hadoop image..."
	tarball=`basename $HADOOP_INSTALL_TARBALL`
	image=`echo $tarball | sed 's/.tar.gz$//' | sed 's/-bin//g'`

	echo "Copying Hadoop tarball to slaves.."
	for node in $slaves
	do
		echo $node
		scp $HADOOP_INSTALL_TARBALL $node:/tmp/
	done

	echo "Installing Hadoop nodes"
	for node in $slaves
	do
		echo $node
		echo ssh $node mkdir -p $HADOOP_BASE
		ssh $node mkdir -p $HADOOP_BASE
		echo ssh $node mkdir -p $HADOOP_INSTALL_DEST
		ssh $node mkdir -p $HADOOP_INSTALL_DEST
		echo ssh $node tar xzf /tmp/$tarball -C $HADOOP_BASE
		ssh $node tar xzf /tmp/$tarball -C $HADOOP_BASE
		echo ssh $node ln -s $HADOOP_BASE/$image $HADOOP_HOME
		ssh $node ln -s $HADOOP_BASE/$image $HADOOP_HOME
		echo ssh $node rm /tmp/$tarball
		ssh $node rm /tmp/$tarball
	done
}

start_hadoop()
{
	# Load Hadoop environment variables
	source $HADOOP_INSTALL_ENV

	echo "Formatting the name node."
	hadoop namenode -format
	if [ $? -ne 0 ]
	then
		echo "Cannot format namenode."
		exit
	fi
	sleep 1

	# Start HDFS service
	echo "Starting HDFS daemon."
	start-dfs.sh
	if [ $? -ne 0 ]
	then
		echo "Cannot start HDFS."
		exit
	fi

	echo "Wait for the HDFS initialization..."
	datanodes=`hadoop dfsadmin -report 2>/dev/null | grep "Datanodes available:" | cut -d' ' -f3`
	slavenodes=`wc -l $HADOOP_HOME/conf/slaves | cut -d' ' -f1`
	while [[ -z "$datanodes" || "$datanodes" -ne "$slavenodes" ]]
	do
		sleep 1
		datanodes=`hadoop dfsadmin -report 2>/dev/null | grep "Datanodes available:" | cut -d' ' -f3`
		if [ -z "$datanodes" ]
		then
			datanodes=0
		fi
		echo "$datanodes of $slavenodes ..."
	done
	echo "Done."

	# Test HDFS
	echo "Testing HDFS."
	hadoop dfs -copyFromLocal $HADOOP_INSTALL_SCRIPTS/tmp/ test
	hadoop dfs -lsr test
	hadoop dfs -rmr test
	if [ $? -ne 0 ]
	then
		echo "Error accessing HDFS."
		exit
	fi
	
	# Start MapReduce
	start-mapred.sh
}
		

stop_hadoop()
{
	# Load Hadoop environment variables
	source $HADOOP_INSTALL_ENV

	# Stop HDFS service
	echo "Stopping HDFS daemon."
	stop-dfs.sh
	if [ $? -ne 0 ]
	then
		echo "Cannot stop HDFS."
		exit
	fi

	# Stop MapReduce service
	echo "Stopping MapReduce daemon."
	stop-mapred.sh
	if [ $? -ne 0 ]
	then
		echo "Cannot stop MapReduce."
		exit
	fi
}


cleanup_tmp()
{
	slaves=`get_nodes`

	for node in $slaves
	do
		echo $node
		ssh $node $HADOOP_INSTALL_SCRIPTS/functions/killall.sh 2>/dev/null
		echo "Removing $HADOOP_BASE ..."
		ssh $node rm -r $HADOOP_BASE 2>/dev/null
		echo "Removing tmp files ..."
		ssh $node rm -r $HADOOP_INSTALL_DEST/hadoop* 2>/dev/null
		ssh $node rm -r /tmp/hadoop* 2>/dev/null
		ssh $node rm -r /tmp/hsperfdata_* 2>/dev/null
		ssh $node rm -rf /tmp/Jetty_* 2>/dev/null
	done
}

