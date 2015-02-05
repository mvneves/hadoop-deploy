#/bin/sh

# Return the allocated nodes list
pbs_nodes()
{
	cat $PBS_NODEFILE | uniq
}

# Return the number of nodes allocated for this job
pbs_nnodes()
{
	cat $PBS_NODEFILE | sort | uniq | wc -l
}

# Return the number of virtual processors allocated for this job
pbs_nproc()
{
	cat $PBS_NODEFILE | wc -l
}

# Return the number of virtual processors per node allocated for this job
pbs_ppn()
{
	nnodes=`pbs_nnodes`
	nproc=`pbs_nproc`
	let ppn=$nproc/$nnodes
	echo $ppn
}

psb_test()
{
	x=`pbs_nproc`
	y=`pbs_nnodes`
	z=`pbs_ppn`

	echo "nproc=$x"
	echo "nnodes=$y"
	echo "ppn=$z"
	echo "node list:"
	pbs_nodes
}

#psb_test


