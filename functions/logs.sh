
date2timestamp()
{
	while read line
	do
		date_str=`echo $line | sed 's/^\([^ ]* [^ ]*\).*/\1/g'`
		#echo $line
		if [ -z "$date_str" ]
		then
			printf "$line\n"
		else
			milisec=`echo $date_str | cut -d',' -f2`
			ts=`date --date="$date_str" +"%s"`
			time="$ts$milisec"
			echo $line | sed "s/^[^ ]* [^ ]*/$time/g"
		fi
	done
}

shuffle_copy2json()
{
	# Usage: shuffle_copy2json <log-dir>

	dir=$1

	printf "{\n  \"shuffleCopy\" : [ \n"

#grep SHUFFLE_COPY $dir -R 2>/dev/null | sed '/Binary file/d' \
#| sed 's/^[^:]*://g' | tr "," " " | \
#awk '{print "\t{\n\t\"time\" : \""$1,$2","$3 "\",\n\t\"reducer\" :\""$8"\",\n\t\"mapper\" : \""$10"\",\n\t\"bytes\" :",$12",\n\t\"startTime\" : "$14",\n\t\"finishTime\" : "$16"\n\t},"}' | \
#sed 's/\(attempt_[0-9]*_[0-9]*_[mr]_[0-9]*_[0-9]*\).*/\1",/g' | sed '$d'

	grep REDUCE_SHUFFLE $dir/tmp/ramdisk/mapred -R 2>/dev/null | sed '/Binary file/d' | sed 's/^[^:]*://g' | \
	date2timestamp | tr "," " " | \
	awk '{print "\t{\n\t\"finishTime\" : "$1 ",\n\t\"reducer\" :\""$6"\",\n\t\"mapper\" : \""$8"\",\n\t\"bytes\" :",$10",\n\t\"duration\" : "$12"\n\t},"}' | \
	sed '$d'
	#sed 's/\(attempt_[0-9]*_[0-9]*_[mr]_[0-9]*_[0-9]*\).*/\1",/g' | sed '$d'
	
	printf "\t} ]\n}"
}

shuffle2json()
{
	# Usage: shuffle2json <log-dir>

	dir=$1

	printf "{\n  \"shuffleTransfer\" : [ \n"

	grep MAPRED_SHUFFLE $dir -R 2>/dev/null | sed '/Binary file/d' | \
	sed 's/^[^:]*://g' | date2timestamp | tr "," " " | \
	awk '{print "\t{\n\t\"finishTime\" : "$1",\n\t\"src\" :\""$5"\",\n\t\"dest\" : \""$7"\",\n\t\"bytes\" :",$9",\n\t\"cliID\" : \""$13"\",\n\t\"reducerID\" : "$17",\n\t\"duration\" : ",$15"\n\t},"}' | \
	sed '$d'

	printf "\t} ]\n}"
}

hdfs2json()
{
	# Usage: hdfs2json <log-dir>

	printf "{\n  \"hdfsTransfers\" : [ \n"

	#grep HDFS_WRITE $dir -R 2>/dev/null | sed '/Binary file/d' | grep DFSClient_attempt_ | \
	#sed 's/DFSClient_attempt_/attempt_/g' | sed 's/^[^:]*://g' | tr "," " " | \
	#awk '{print "\t{\n\t\"type\" : \"HDFS_WRITE\",\n\t\"time\" : \""$1,$2","$3 "\",\n\t\"src\" :\""$7"\",\n\t\"dest\" : \""$9"\",\n\t\"bytes\" :",$11",\n\t\"cliID\" : \""$15"\",\n\t\"duration\" : ",$23",\n\t\"startTime\" : "$25",\n\t\"finishTime\" : "$27"\n\t},"}' | \
	#sed 's/\(attempt_[0-9]*_[0-9]*_[mr]_[0-9]*_[0-9]*\).*/\1",/g' | sed '$d'

	grep HDFS_WRITE $dir -R 2>/dev/null | sed '/Binary file/d' | grep DFSClient_attempt_ | \
	sed 's/DFSClient_attempt_/attempt_/g' | sed 's/^[^:]*://g' | date2timestamp | tr "," " " | \
	awk '{print "\t{\n\t\"type\" : \"HDFS_WRITE\",\n\t\"finishTime\" : "$1",\n\t\"src\" :\""$5"\",\n\t\"dest\" : \""$7"\",\n\t\"bytes\" :",$9",\n\t\"cliID\" : \""$13"\",\n\t\"duration\" : ",$21"\n\t},"}' | \
	sed 's/\(attempt_[0-9]*_[0-9]*_[mr]_[0-9]*_[0-9]*\).*/\1",/g' | sed '$d'

	printf "\t} ]\n}"
}

rumen()
{
	# Usage: rumen <jobtrace-output> <topology-output> <jobhistory-input-folder>
	jh=$1
	topo=$2
	log=$3

	if [ -z "$HADOOP_HOME" ]
	then
		echo "\$HADOOP_HOME not configured."
		return
	fi

	cp=`echo $HADOOP_HOME/*.jar $HADOOP_HOME/lib/*.jar | tr ' ' ':'`

	java -cp $cp org.apache.hadoop.tools.rumen.TraceBuilder $jh $topo $log
}

gen_job_history()
{
	# Usage: gen_job_history <dir>
	dir=$1

	pushd $dir

	for i in hadoop-logs*.tar
	do
		echo $i
		tar xf $i
	done

	mkdir -p job_history
	for i in `find * | grep history | grep '/job_'`
	do
		#echo $i
		cp $i job_history
	done

	shuffle_copy2json $dir > $dir/shuffle-copies.json
    hdfs2json $dir > $dir/hdfs-transfers.json
	shuffle2json $dir > $dir/shuffle-transfers.json

	rm -rf mapred tmp
	
	echo "Running rumen ..."
	for i in `find job_history | sed '/conf/d'`
	do
		echo $i
		rumen $i.json topology.json $i
	done
	
	popd
}

iptraf_date2timestamp()
{
	while read line
	do
		str=`echo $line | sed 's/^\([^;]*\).*/\1/g'`
		ts=`date --date="$str" +%s`
		echo "$ts; $line"
	done
}


iptraf2json()
{
	logfile=$1
	host=`basename $logfile | sed 's/.*-\([0-9]*.[0-9]*.[0-9]*.[0-9]*\).txt$/\1/g'`

	printf "{\n  \"iptraf\" : [ \n"

	cat $logfile | egrep "FIN sent|first packet" | iptraf_date2timestamp | tr -d ';' | \
	while read line
	do
		x=`echo $line | grep "FIN sent"`
		if [ -n "$x" ]
		then
			fn=`echo $x | awk '{print $12"_"$14"_startTime.txt"}'`
	
			if [ ! -e "/tmp/$fn" ]
			then
				continue
			fi
			startTime=`head -n 1 /tmp/$fn`
			rm -f /tmp/$fn
			echo $x | awk -v st=$startTime -v lh=$host '{print "\t{\n \t\"startTime\" : "st",\n\t\"finishTime\" : "$1",\n\t\"localhost\" : \""lh"\",\n\t\"iface\" : \""$8"\",\n\t\"src\" : "$12"\",\n\t\"dest\" : \""$14"\",\n\t\"packets\" : "$17",\n\t\"bytes\" : "$19",\n\t\"avg_rate\" : "$24"\n\t},"}'
		else
			#echo $line
			fn=`echo $line | awk '{print $12"_"$14"_startTime.txt"}'`
			startTime=`echo $line | awk '{print $1}'`
			echo $startTime > /tmp/$fn
		fi
	done
}

iptraf_process_logs()
{
	dir=$1

	for txt in `find $dir/iptraf/iptraf-*.txt` 
	do
		json=`echo $txt | sed 's/.txt$/.json/g'`
		iptraf2json $txt | sed '$d' > $json
		printf "\t} ]\n}" >> $json
	done
}


