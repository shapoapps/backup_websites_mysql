#!/bin/bash


#MySQL backup user data
MYSQLUSER='mysql_user'
MYSQLPASSWORD='password'

#How much days we store backups
DAYS_TO_KEEP_BACKUPS_ON_SERVER=7



#Array of sites names
sites_array=(/mysite1.com/ /mysite2.com/ /mysite3.com/)



#Get current directory of the script
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#File with folders for backup
FOLDERS=$CURDIR/files_to_backup.txt

#Databases names for backup
DATABASES=$CURDIR/databases_to_backup.txt


#Folder to store archived backups

#Files folder
ARCHIVED_FILES_FOLDER=$CURDIR/backup

#Databases folder
ARCHIVED_DATABASES_FOLDER=$CURDIR/backup_bd


#Clear temporary folder before first run
rm -r -f $CURDIR/temp_folder



mkdir $CURDIR/temp_folder
mkdir $CURDIR/temp_folder/files
mkdir $CURDIR/temp_folder/databases


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


    #Current date, time
    date=$(date +"%d.%m.%y--%H-%M-%S")

    ARCHIVE_READY=2

    for i in "${sites_array[@]}"; 
    do

        if [[ $line =~ "$i" ]];
        then
          echo "found overlap,"$i
          echo $line
          SITE_FILENAME="${i//\//$''}"

          rsync -a $line $CURDIR/temp_folder/files
          zip -r $ARCHIVED_FILES_FOLDER/$date-$SITE_FILENAME-backup.zip $CURDIR/temp_folder/files/

          #Delete temporary folder
          rm -r -f $CURDIR/temp_folder/files

          mkdir $CURDIR/temp_folder/files
          ARCHIVE_READY=1
        else
          echo "overlap not found"
        fi
    done

    if [ "$ARCHIVE_READY" -ne 1 ];
    then
	    rsync -a $line $CURDIR/temp_folder/files
	    zip -r $ARCHIVED_FILES_FOLDER/$date-undefined_site-backup.zip $CURDIR/temp_folder/files/

	    #Delete temporary folder
	    rm -r -f $CURDIR/temp_folder/files

	    mkdir $CURDIR/temp_folder/files
	    ARCHIVE_READY=1
    fi

done < "$FOLDERS"




while read -r line; 
do
    #Check for backspaces
    if [ "${#line}" -lt 2 ] || [ -z "$line" ] ; 
    then
	    echo "Skipping database: $line"
	    continue
    fi

    mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD --databases $line > $CURDIR/temp_folder/databases/$line.sql

done < "$DATABASES"



#Backup users, users permissions on databases
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql user > $CURDIR/temp_folder/databases/user_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql db > $CURDIR/temp_folder/databases/db_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql tables_priv > $CURDIR/temp_folder/databases/tables_priv_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql columns_priv > $CURDIR/temp_folder/databases/columns_priv_table_dump.sql
mysqldump -u $MYSQLUSER -p$MYSQLPASSWORD mysql procs_priv > $CURDIR/temp_folder/databases/procs_priv_table_dump.sql


#Archiving databases (zip must be installed in system)
zip -r $ARCHIVED_DATABASES_FOLDER/$date-databases-backup.zip $CURDIR/temp_folder/databases/


#Delete temporary folder 
rm -r -f $CURDIR/temp_folder



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

