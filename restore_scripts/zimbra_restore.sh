#!/bin/bash

TZ='Europe/Moscow'; export TZ

# Result of script execution
export state='OK'


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

function fin() {
    # Calculating time
    after="$(date +%s)"
    elapsed="$(expr $after - $before)"
    hours=$(($elapsed / 3600))
    elapsed=$(($elapsed - $hours * 3600))
    minutes=$(($elapsed / 60))
    seconds=$(($elapsed - $minutes * 60))
    
    echo >> $outf
    echo >> $outf
    echo "The complete restore lasted: $hours hours $minutes minutes $seconds seconds" >> $outf
    echo >> $outf
    echo "Restore finished with state: $state" >> $outf

    # Now email results
    cat $outf | mutt -s "$state Zimbra restore" -- admin@company.net
    exit
}


echo `date '+%Y/%m/%d %A %T'` > $outf
echo >> $outf
echo "SCRIPT:      $0" >> $outf
echo "SERVER:      `uname -n` (reserve)" >> $outf
echo "CRON USER:   `whoami`" >> $outf
echo >> $outf
echo >> $outf


echo "`date +%T` Start 'restore database dump'..." >> $outf
su - zimbra -c /opt/zimbra/bin/db_restore.sh

retval=$?
echo "`date +%T` Dump restore exit_code: $retval" >> $outf
ck_retval $retval


echo "`date +%T` Start 'restore ldap main data'..." >> $outf
cd /opt/zimbra/data/ldap
mv -f mdb /backup/old/mdb_`date -I`
mkdir -p mdb/db
chown -R zimbra:zimbra /opt/zimbra/data/ldap
sudo -u zimbra /opt/zimbra/libexec/zmslapadd /opt/zimbra/backup/ldap/ldap.bak

retval=$? 

if [ $retval -eq 0 ]; then
    rm -rf /backup/old/mdb_`date -I`
fi

echo "`date +%T` LDAP main restore exit_code: $retval" >> $outf
ck_retval $retval


echo "`date +%T` Start SSL keys restoring..." >> $outf
for i in cert.pem chain.pem fullchain.pem privkey.pem; do
    cat /etc/letsencrypt/live/mail.extracode.net/$i >> /opt/zimbra/ssl/lcerts/$i
done

cat /root/lcerts/x3root.ca >> /opt/zimbra/ssl/lcerts/chain.pem
cp -u /opt/zimbra/ssl/lcerts/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key

chown -R zimbra:zimbra /opt/zimbra/ssl/lcerts
su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm ~/ssl/lcerts/cert.pem ~/ssl/lcerts/chain.pem"

# this ends with 1 rc
retval=$?
echo "`date +%T` SSL keys restoring; exit_code: $retval" >> $outf
# ck_retval $retval
echo "`su - zimbra -c \"/opt/zimbra/bin/zmcertmgr viewdeployedcrt\"`" >> $outf

for i in cert.pem chain.pem fullchain.pem privkey.pem; do
    rm -rf /opt/zimbra/ssl/lcerts/$i
done


fin

