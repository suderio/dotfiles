#!/bin/sh
# usage mysqlbackup.sh <HOST> <PORT> <USER> <DESTINATION>
mysqldump -h "$1" -P "$2" -u"$3" --password \
  --max_allowed_packet=512M \
  --set-gtid-purged=OFF \
  --single-transaction \
  --quick --lock-tables \
  --triggers \
  --routines \
  --events \
  --ignore-table=mysql.innodb_table_stats \
  --ignore-table=mysql.innodb_index_stats \
  --all-databases > "$4/mysqldump-$1.$(date  +"%Y%m%d").sql"
