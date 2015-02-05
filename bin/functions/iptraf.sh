
date2timestamp()
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

	cat $logfile | egrep "FIN sent|first packet" | date2timestamp | tr -d ';' | \
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

process_iptraf()
{
	dir=$1

	for txt in `find $dir/iptraf/iptraf-*.txt` 
	do
		json=`echo $txt | sed 's/.txt$/.json/g'`
		iptraf2json $txt | sed '$d' > $json
		printf "\t} ]\n}" >> $json
	done
}


