# /bin/bash
USUARIO="root"
PASSWORD="3jYn22hgqXZJVxjn"
DESTINO="s3://backups-dbase/ALISEDA_&_LADESPENSA/CHECKSUM"
NOW=$(date "+%Y-%m-%d")
TITLE="mysql"
INFO="information_schema"
I="ysrm"
PERFORMANCE="performance_schema"
mysql -u root -p3jYn22hgqXZJVxjn -e "show databases;" > databases.txt
for db in $(cat databases.txt)
do
  filename="$NOW - $db.sql.gz"
  tmpfile="/tmp/$filename"
  object="$DESTINO/$NOW/$filename"

  mysql -u root -p3jYn22hgqXZJVxjn -e "use $db; show tables;" > "/tmp_backups/$db-tables.txt"

  CHANGES=false
  for table in $(cat "/tmp_backups/$db-tables.txt")
  do
        if [[ "$table" !=  "Tables_in_$db" ]]; then
                echo "-------------- NO ES Tables_into ---------------"
                mysql -u root -p3jYn22hgqXZJVxjn -e "use $db; CHECKSUM table $table;" > "/tmp_backups/$db-$table-CHECKSUM.txt"

                muevo_archivo="/tmp_backups/$db-$table-CHECKSUM.txt"
                antiguo_archivo="/tmp_backups/$db-$table-CHECKSUM-OLD.txt"

                ACTUAL_CHECKSUM=$(head -n 2 "/tmp_backups/$db-$table-CHECKSUM.txt")
                ULTIMO_CHECKSUM=$(head -n 2 "/tmp_backups/$db-$table-CHECKSUM-OLD.txt")

                echo "--------$ACTUAL_CHECKSUM actual --------"
                echo "--------$ULTIMO_CHECKSUM ultimo --------"

                if [[ "$ACTUAL_CHECKSUM" != "$ULTIMO_CHECKSUM" ]]; then
                        echo "------------CAMBIOS------------"
                        let CHANGES=true
                        rm -rf "/tmp_backups/$db-$table-CHECKSUM-OLD.txt"
                        mv "/tmp_backups/$db-$table-CHECKSUM.txt" "/tmp_backups/$db-$table-CHECKSUM-OLD.txt"
                fi
        fi
  done

  if [[ "$CHANGES" != false && "$db" != $TITLE && "$db" != $INFO && "$db" != $I  && "$db" != $PERFORMANCE ]]; then
     mysqldump --user=$USUARIO --password=$PASSWORD "$db" | gzip -c > "$tmpfile"
     s3cmd put "$tmpfile" "$object"

     rm -f "$tmpfile"
  fi
done
