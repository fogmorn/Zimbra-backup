#!/bin/bash

# Result of script execution
export state='OK'

# Path to mysql dump file
export dumpf="/backup/zimbra/database/mysqldump_`date -I`.sql"

# Path to store log file
export outf='/opt/zimbra/log/zimbra_backup.log'

# For time calculations
before=$(date +%s)


# Check return value of executed commands
function ck_retval() {
    if [ $1 -ne 0 ]; then
        state='Failed'
        fin
    fi
}

# Now email results
function fin() {
    # Calculating time
    after="$(date +%s)"
    elapsed="$(expr $after - $before)"
    hours=$(($elapsed / 3600))
    elapsed=$(($elapsed - $hours * 3600))
    minutes=$(($elapsed / 60))
    seconds=$(($elapsed - $minutes * 60))
    
    echo "The complete backup lasted: $hours hours $minutes minutes $seconds seconds" >> $outf
    echo >> $outf
    echo "Backup finished with state: $state">> $outf

    cat $outf | mutt -s "$state Zimbra backup" -- admin@company.net
    exit
}


echo `date '+%Y/%m/%d %A %T'` > $outf
echo >> $outf
echo "SCRIPT:      $0" >> $outf
echo "SERVER:      `uname -n`" >> $outf
echo "CRON USER:   `whoami`" >> $outf
echo >> $outf
echo >> $outf


# Clean up previous backup data
rm -rf /backup/zimbra/database/*
rm -rf /backup/zimbra/ldap/*


echo "`date +%T` Start mysqldump..." >> $outf
sudo -u zimbra /opt/zimbra/bin/dump.sh

retval=$?
gzip $dumpf
echo "`date +%T` Done mysqldump; exit_code: $retval" >> $outf
echo >> $outf
ck_retval $retval


echo "`date +%T` Start rsync mysqldump..." >> $outf
rsync --delete -azHKS --bwlimit=800 /backup/zimbra/database/* \
                                    user@server/opt/zimbra/backup/database/
retval=$?
echo "`date +%T` Done rsync mysqldump; exit_code: $retval" >> $outf
echo >> $outf
ck_retval $retval


echo "`date +%T` Start backup and rsync ldap data..." >> $outf
sudo -u zimbra /opt/zimbra/libexec/zmslapcat /backup/zimbra/ldap
rsync --delete -azHKS --bwlimit=800 /backup/zimbra/ldap/* \
                      user@server:/opt/zimbra/backup/ldap/

retval=$?
echo "`date +%T` Done backup and rsync ldap data; exit_code: $retval" >> $outf
echo >> $outf
ck_retval $retval


echo "`date +%T` Start rsync /opt/zimbra/store..." >> $outf
rsync --delete -azHKS --bwlimit=800 /opt/zimbra/store/* \
                                    user@server:/opt/zimbra/store/

retval=$?
echo "`date +%T` Done rsync /opt/zimbra/store; exit_code: $retval" >> $outf
echo >> $outf
ck_retval $retval


echo "`date +%T` Start rsync /opt/zimbra/index..." >> $outf
rsync --delete -azHKS --bwlimit=800 /opt/zimbra/index/* \
                                    user@server:/opt/zimbra/index/

retval=$?
echo "`date +%T` Done rsync /opt/zimbra/store; exit_code: $retval" >> $outf
echo >> $outf
ck_retval $retval

rsync --delete -azHKS /etc/letsencrypt/* user@server:/etc/letsencrypt/

fin


