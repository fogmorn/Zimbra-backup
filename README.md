# Zimbra-backup
Скрипты для бэкапа и восстановления почтового сервера Zimbra.  
 - Бэкап включает в себя mail_store, index_store, ldap_data, mysql_database, ssl_certificates.  
 - На каждом этапе происходит проверка кода завершения команды.  
 - Логи stderr, stdout пишутся на серверах в `/opt/zimbra/log/zimbra_backup.log`  
 - По завершении процесса бэкапа/восстановления выполняется отправка письма с отчётом.

## Процесс бэкапа
Процесс выполняется на исходном (Live) сервере.  
1. [cron](backup_scripts/root_cron) задание запускает основной скрипт бэкапа [zimbra_backup.sh](backup_scripts/zimbra_backup.sh).
2. Основной скрипт бэкапа запускает скрипт бэкапа **базы данных MySQL** [dump.sh](backup_scripts/dump.sh).
3. Созданный бэкап БД копируется на целевой сервер, где будет в последствии восстановлен.
4. Создаётся бэкап **ldap** данных и копируется на целевой сервер.
5. Запускается синхронизация **хранилища писем** с целевым сервером.
6. Запускается синхронизация **индекса писем**.
7. Копируется папка с **SSL сертификатами**.

## Процесс восстановления
Процесс выполняется на целевом (StandBy) сервере.  
1. [cron](restore_scripts/root_cron) задание запускает основной скрипт восстановления [zimbra_restore.sh](restore_scripts/zimbra_restore.sh).
2. Основной скрипт восстановления запускает скрипт восстановления **базы данных MySQL** [db_restore.sh](restore_scripts/db_restore.sh).
3. Восстанавливаются **ldap** данные.
4. Восстанавливается **SSL сертификат**.
