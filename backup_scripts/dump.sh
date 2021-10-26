#!/bin/bash

export _mysqldump='/opt/zimbra/common/bin/mysqldump'
export dumpf="/backup/zimbra/database/mysqldump_`date -I`.sql"

source ~/bin/zmshutil
zmsetvars

$_mysqldump --user=root \
            --password=$mysql_root_password \
            --all-databases \
            --socket=$mysql_socket \
            --single-transaction \
            --flush-logs > $dumpf

exit $?
