# hadoop-deploy
Automated Hadoop Cluster Deployment Scripts

This is a set of scripts to run Hadoop MapReduce applications in shared clusters (e.g., HPC clusters).
We have successfully used it to run Hadoop experiments in a HPC cluster managed by TORQUE/PBS. 

# How to deploy a Hadoop cluster

In summary:

- modify INSTALL.config to configure the instalation
- create a machines.txt with the hostnames of all nodes
- run hadoop-discover-cluster.sh
- run hadoop-deploy.sh to create a Hadoop cluster installion
- run any Hadoop aplications
- run hadoop-destroy.sh to destroy the Hadoop cluster

## Running a Hadoop experiment step-by-step

These are the steps required to install a Hadoop cluster and run an experiment.

### Configure and discover cluster nodes

First of all, you need to configure the instalation using the INSTALL.config file:

	cat INSTALL.config


Create a machines.txt file with the hostnames of all nodes:

	cat machines.txt
	cerrado04
	cerrado05
	cerrado06
	cerrado07


Discover cluster nodes:

	hadoop-discover-cluster.sh


### Deploy Hadoop cluster

Create Hadoop cluster:

	hadoop-deploy.sh


At this point, the Hadoop cluster is ready and you can submit your jobs.

### Save and post-process log files

You must especify a name to the experiment (e.g., test1).
The Hadoop log files and the generated .json files will be placed in a tarball
in the current directory.

	hadoop-save_logs.sh test1

### Destroy Hadoop cluster

Destroy Hadoop cluster. All Hadoop-related files will be removed.

	hadoop-destroy.sh

