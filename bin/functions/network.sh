

get_local_address() {
    iface=$1
    ip=`/sbin/ifconfig $iface | grep "inet addr:" | sed -r 's/.*inet addr:([0-9.]+).*/\1/g'`
    echo $ip
}

get_remote_address() {
    nome=$1
    iface=$2
    ip=`ssh $node /sbin/ifconfig $iface | grep "inet addr:" | sed -r 's/.*inet addr:([0-9.]+).*/\1/g'`
    echo $ip
}

# TODO: this may not work for all systems
get_local_hostname() {
	ip=$1
	name=`grep $ip /etc/hosts | awk '{print $2}'`
	echo $name
}

get_remote_hostname() {
	ip=$1
	name=`ssh $ip grep $ip /etc/hosts | awk '{print $2}'`
	echo $name
}

update_hostname() {
	ip=$1
	name=`get_remote_hostname $ip`
	if [ -z "$name" ]
	then
		echo "hostname not found for $ip"
		return
	fi
	echo "Setting hostname $name for $ip ..."
	ssh -t $ip sudo hostname $name
}


