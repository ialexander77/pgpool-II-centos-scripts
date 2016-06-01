#!/bin/bash

# Load pgpool functions
. $(dirname $0)/pgpool.sh

attach()
{
	_attach $1
}

detach()
{
	_detach $1
}

recover()
{
	_recover $1
}

status()
{
	nodes=$(_get_node_count)

	if [ $? -gt 0 ]; then
		echo "ERROR: Failed to get node count: $nodes" >&2
		exit 1
	fi

	c=0

	while [ $c -lt $nodes ]; do
		_get_node_status $c
		let c=c+1
	done
}

if [ ! "$(type -t $1)" ]; then
	echo "Usage $0 <option>" >&2
	echo "" >&2
	echo "Available options:" >&2
	echo "$(compgen -A function |grep -v '^_')" >&2
	exit 99
else
	cmd=$1
	shift
	$cmd $*

	exit $?
fi

