#!/bin/bash

# Variables
failed_node=$1
new_master=$2
trigger_file=$3

# Load pgpool functions
. $(dirname $0)/pgpool.sh

if [ "$(_get_master_node)" != "$failed_node" ] ; then
	exit 0;
fi

/usr/bin/ssh -T $new_master -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no" /bin/touch $trigger_file

exit 0;
