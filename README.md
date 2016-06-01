# Pgpool-II-9.4 config files and scripts for Centos 6.x + quick start guide.

Before deployment pgpool-II on Centos 6.x we would need to prepare the 2 cluster nodes.
Place folder "nodes" on cluster nodes and "pgpool" on pgpool server

### 1. Configure pg_hba.conf add the following lines regarding your configuration (less securesed, for more secure way use md5 password acsess)

    local   all             all                                     trust
    host    replication     postgres        xxx.xxx.xxx.xxx/32      trust

### 2. Enable WAL replication

    disable SELinux in /etc/selinux/config: SELINUX=disabled
    configure iptables on both servers to allow 5432 port from both servers:
    '-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp -s IP_MASTER --dport 5432 -j ACCEPT #(insert on slave)'
    '-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp -s IP_SLAVE --dport 5432 -j ACCEPT #(insert on master)'
    stop postgres on slave
    execute on master: psql -U postgres -c "SELECT pg_start_backup('label', true)"
    rsync -avz --exclude postgresql.conf --exclude postmaster.opts --exclude postmaster.pid --exclude server.crt --exclude server.key /var/lib/pgsql/9.4/data slaveIP:/var/lib/pgsql/9.4/
    execute on master: psql -U postgres -c "SELECT pg_stop_backup()"
    make changes to recovery.conf (example attached)
    run postgres on slave
    check replication on slave: ps ax | grep [r]eceiver

### 3. Setup passwordless access for postgres user

    su postgres -
    On master and slave servers:
    ssh-keygen -t rsa
    On both:
    cd ~/.ssh/
    touch authorized_keys
    copy content id_rsa.pub into authorized_keys across servers
    exit

### 4. Install support files on both servers

    rpm -Uvh http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm
    yum update
    yum -y install pgpool-II-94 pgpool-II-94-extensions

### 5. Create pgpool functions

    psql -U postgres -f pgpool-recovery.sql template1

### 6. Allow execute sudo under ssh

    sed -i.bak s/'Defaults    requiretty'/'#Defaults    requiretty'/g /etc/sudoers
    echo 'postgres ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

### 7. Copy scripts to default data folder, modify postgresql.conf and recovery.conf to your needs

    cp basebackup.sh /var/lib/pgsql/9.4/data/
    cp pg_hba.conf /var/lib/pgsql/9.4/data/
    cp pgpool_remote_start /var/lib/pgsql/9.4/data/
    cp postgresql.conf /var/lib/pgsql/9.4/data/
    cp recovery.conf /var/lib/pgsql/9.4/data/
    
### 8. Chown to postgres user

    chown -R postgres:postgres /var/lib/pgsql/9.4/data

### 9. Configure pgpool-II

    copy files (failover_stream.sh, pgpool.conf, pgpool_follow_master.sh, pgpoolmgr.sh, pgpool.sh, pool_hba.conf) to /etc/pgpool-II-94
    make changes to pgpool.sh pool_hba.conf and pgpool.conf
    create pcp.conf from sample and generate password: pg_md5 P@ssw0rd
    insert in the end of pcp.conf the line (change md5 password to result in previous step): pcp:161ebd7d45089b3446ee4e0d86dbcf92
    start pgpool-II
    check the node status: cat /var/log/pgpool-II-94/pgpool_status

### 10. Use of management script

    cd to /etc/pgpool-II-94 and execute: ./pgpoolmgr.sh status
    other available options: attach, detach, recover
    
### 11. Alternate recovery way

    pcp_recovery_node -d 10 localhost 9898 pcp P@ssw0rd 1 #(where 0 or 1 node number to recover)    
