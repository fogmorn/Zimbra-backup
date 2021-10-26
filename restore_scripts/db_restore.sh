#!/bin/bash

export dump_d='/opt/zimbra/backup/database'
export dump_f="${dump_d}/mysqldump_`date -I`.sql"
export prev_dump_f="${dump_d}/mysqldump_`date -d '-4 day' '-I'`.sql"

# Delete previous dump
rm $prev_dump_f

gunzip ${dump_f}.gz


source ~/bin/zmshutil; zmsetvars
mysql.server start


mysql --user=root --password=$mysql_root_password --socket=$mysql_socket < ${dump_f}
RETVAL=$?


mysql.server stop
exit $RETVAL
