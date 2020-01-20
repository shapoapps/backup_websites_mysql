#!/bin/bash


#MySQL backup user data
MYSQLUSER='mysql_user'
MYSQLPASSWORD='mysql_password'

#How much days we store backups
DAYS_TO_KEEP_BACKUPS_ON_SERVER=4



#Array of sites names
sites_array=(/mysite1.com/ /mysite2.com/ /mysite3.com/)


#Databases backup flag, if flag = 1, script take databases names from text file databases_to_backup.txt , if flag = 2 script backup all databases
DB_MODE_FLAG=2



#Get current directory of the script
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#File with folders for backup
FOLDERS=$CURDIR/files_to_backup.txt

#Databases names for backup
DATABASES=$CURDIR/databases_to_backup.txt


#File to store logs folders skeleton
FOLDERS_STRUCTURE_TO_STORE=$CURDIR/folders_skeleton.txt


#Folder to store archived backups

#Files folder
ARCHIVED_FILES_FOLDER=/backups_server

#Databases folder
ARCHIVED_DATABASES_FOLDER=/backups_server




#Clear temporary folder before first run
rm -r -f /tmp/temp_folder


mkdir /tmp/temp_folder
mkdir /tmp/temp_folder/settings
mkdir /tmp/temp_folder/files
mkdir /tmp/temp_folder/databases







#Archiving folders skeleton
#Current date, time


while read -r folders_skeleton;
do

    #Check for backspaces
    if [ "${#folders_skeleton}" -lt 5 ] || [ -z "$folders_skeleton" ] ; 
    then
	      echo "Skipping path: $folders_skeleton"
	      continue
    fi

    #Check is path for archivation exists
    if [ ! -d $folders_skeleton ]; then
	      echo "Path does not exist."
        continue
    fi


    find $folders_skeleton -type d >> /tmp/temp_folder/settings/skeleton_of_folders.txt

done < "$FOLDERS_STRUCTURE_TO_STORE"



#Export system settings

#export crontab rules
crontab -l > /tmp/temp_folder/settings/crontab.bak

#Export list of all installed programs in system with their versions
sudo dpkg -l > /tmp/temp_folder/settings/allinstalledprogs.txt


#Export network settings
echo "------------------------------------***********------------------------------------" > /tmp/temp_folder/settings/networkinterfaces.txt
echo "command: ip link show" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
ip link show >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt

echo "command: netstat -i" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
netstat -i >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt

echo "command: ifconfig" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
ifconfig  >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt

echo "command: ip r" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
ip r >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt

echo "command: netstat -ntlpu" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
netstat -ntlpu >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt

echo "command: ufw status numbered" >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "" >> /tmp/temp_folder/settings/networkinterfaces.txt
ufw status numbered >> /tmp/temp_folder/settings/networkinterfaces.txt
echo "------------------------------------***********------------------------------------" >> /tmp/temp_folder/settings/networkinterfaces.txt


#Export nginx settings
nginx -V 2>&1 | tee /tmp/temp_folder/settings/nginx_settings.txt
php -m > /tmp/temp_folder/settings/php_extensions_installed.txt

tar cvpzf $ARCHIVED_FILES_FOLDER/$(date +"%d.%m.%y--%H-%M-%S")-settings-backup.tar.gz /tmp/temp_folder/settings/







while read -r line; 
do

    #Check for backspaces
    if [ "${#line}" -lt 5 ] || [ -z "$line" ] ; 
    then
	      echo "Skipping path: $line"
	      continue
    fi

    #Check is path for archivation exists
    if [ ! -d $line ]; then
	echo "Path does not exist."
        continue
    fi


    ARCHIVE_READY=2

    for i in "${sites_array[@]}"; 
    do

        if [[ $line =~ "$i" ]];
        then
          echo "found overlap,"$i
          echo $line
          SITE_FILENAME="${i//\//$''}"

          rsync -a -R $line /tmp/temp_folder/files

	  tar cvpzf $ARCHIVED_FILES_FOLDER/$(date +"%d.%m.%y--%H-%M-%S")-$SITE_FILENAME-backup.tar.gz /tmp/temp_folder/files

          #Delete temporary folder
          rm -r -f /tmp/temp_folder/files

          mkdir /tmp/temp_folder/files
          ARCHIVE_READY=1
        else
          echo "overlap not found"
        fi
    done

    if [ "$ARCHIVE_READY" -ne 1 ];
    then
	    rsync -a -R $line /tmp/temp_folder/files
	    
	    tar cvpzf $ARCHIVED_FILES_FOLDER/$(date +"%d.%m.%y--%H-%M-%S")-undefined_site-backup.tar.gz /tmp/temp_folder/files
	    

	    #Delete temporary folder
	    rm -r -f /tmp/temp_folder/files

	    mkdir /tmp/temp_folder/files
	    ARCHIVE_READY=1
    fi

done < "$FOLDERS"






if [ "$DB_MODE_FLAG" -eq 1 ] ;
then
    #Backup databases defined in txt file
    while read -r line; 
    do
	#Check for backspaces
	if [ "${#line}" -lt 2 ] || [ -z "$line" ] ; 
	then
	    echo "Skipping database: $line"
	    continue
	fi

	mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD --databases $line > /tmp/temp_folder/databases/$line.sql

    done < "$DATABASES"
else
    #Backup all databases

    databases=`mysql -u $MYSQLUSER -p$MYSQLPASSWORD -e "SHOW DATABASES;" | tr -d "|" | grep -v Database`

    for db in $databases; do

	if [ $db == 'information_schema' ] || [ $db == 'performance_schema' ] || [ $db == 'mysql' ] || [ $db == 'sys' ]; then
	    echo "Skipping database: $db"
	    continue
	fi

	mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD --databases $db > /tmp/temp_folder/databases/$db.sql

    done

fi



#Backup users, users permissions on databases
mysql -u $MYSQLUSER -p$MYSQLPASSWORD --skip-column-names -A -e"SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user<>''" | mysql -u $MYSQLUSER -p$MYSQLPASSWORD --skip-column-names -A | sed 's/$/;/g' > /tmp/temp_folder/databases/MySQLUserGrants.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql user > /tmp/temp_folder/databases/user_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql db > /tmp/temp_folder/databases/db_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql tables_priv > /tmp/temp_folder/databases/tables_priv_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql columns_priv > /tmp/temp_folder/databases/columns_priv_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql procs_priv > /tmp/temp_folder/databases/procs_priv_table_dump.sql


#Archiving databases 
tar cvpzf $ARCHIVED_DATABASES_FOLDER/$(date +"%d.%m.%y--%H-%M-%S")-databases-backup.tar.gz /tmp/temp_folder/databases/



#Delete temporary folder 
rm -r -f /tmp/temp_folder



#Delete old backups
if [ "$DAYS_TO_KEEP_BACKUPS_ON_SERVER" -gt 0 ] ;
then
    #safety check for empty strings in path ARCHIVED_FILES_FOLDER
    $ARCHIVED_FILES_FOLDER = ${ARCHIVED_FILES_FOLDER##*( )}
    if [ "${#ARCHIVED_FILES_FOLDER}" -lt 5 ] || [ -z "$ARCHIVED_FILES_FOLDER" ] ; 
    then
	    echo "Skipping path: $ARCHIVED_FILES_FOLDER"
	    continue
    else
	    echo "Deleting backups older than $DAYS_TO_KEEP_BACKUPS_ON_SERVER days"
	    find $ARCHIVED_FILES_FOLDER/* -mtime +$DAYS_TO_KEEP_BACKUPS_ON_SERVER -exec rm {} \;
	    find $ARCHIVED_FILES_FOLDER/* -mtime +$DAYS_TO_KEEP_BACKUPS_ON_SERVER -exec rm {} \;
    fi


    #safety check for empty strings in path ARCHIVED_DATABASES_FOLDER
    $ARCHIVED_DATABASES_FOLDER = ${ARCHIVED_DATABASES_FOLDER##*( )}
    if [ "${#ARCHIVED_DATABASES_FOLDER}" -lt 5 ] || [ -z "$ARCHIVED_DATABASES_FOLDER" ] ; 
    then
	    echo "Skipping path: $ARCHIVED_DATABASES_FOLDER"
	    continue
    else
	    echo "Deleting backups older than $DAYS_TO_KEEP_BACKUPS_ON_SERVER days"
	    find $ARCHIVED_DATABASES_FOLDER/* -mtime +$DAYS_TO_KEEP_BACKUPS_ON_SERVER -exec rm {} \;
	    find $ARCHIVED_DATABASES_FOLDER/* -mtime +$DAYS_TO_KEEP_BACKUPS_ON_SERVER -exec rm {} \;
    fi
fi

