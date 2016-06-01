#!/bin/bash


datadir=$1
desthost=$2

psql -c "SELECT pg_start_backup('Streaming Replication', true)" postgres

ssh postgres@$desthost -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no" "sudo /etc/init.d/postgresql-9.4 stop > /dev/null ; rm $datadir/postgresql.trigger > /dev/null 2>&1  ; rm $datadir/recovery.done > /dev/null 2>&1"

ssh postgres@$desthost -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no" "cat > $datadir/recovery.conf <<EOF
standby_mode = on
trigger_file = '/var/lib/pgsql/9.4/data/postgresql.trigger'
primary_conninfo = 'host=`hostname -f` port=5432 user=postgres'
recovery_target_timeline='latest'
EOF"

rsync -C -a --delete -e 'ssh -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no"' --exclude pg_log --exclude pg_xlog --exclude recovery.conf --exclude recovery.done --exclude postgresql.conf --exclude pg_hba.conf --exclude postmaster.opts --exclude postmaster.pid --exclude server.crt --exclude server.key $datadir/ $desthost:$datadir/

psql -c "SELECT pg_stop_backup()" postgres

rsync -C -a --delete -e 'ssh -o "VerifyHostKeyDNS no" -o "StrictHostKeyChecking no"' $datadir/pg_xlog/ $desthost:$datadir/pg_xlog/
