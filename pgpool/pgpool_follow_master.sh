#!/bin/bash
 
# Variables
slave_node=$1
old_master_node=$2
new_master=$3
cluster_path=$4

# Load pgpool functions
. $(dirname $0)/pgpool.sh

# Check if slave not in standby
if [ "$(_is_standby $slave_node)" != "1" ] ; then
	exit 0;
fi

# Get node ID
node_info=($(_get_node_info $slave_node))
node_hostname=(${node_info[0]})

# Reconfigure slave
/usr/bin/ssh -t $node_hostname -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no" "perl -i -pe 's/host=\S*/host='$new_master'/' $cluster_path/recovery.conf"

# Restart slave
/usr/bin/ssh -t $node_hostname -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no" "sudo /etc/init.d/postgresql-9.4 restart > /dev/null"

# Attach slave
_attach $slave_node
