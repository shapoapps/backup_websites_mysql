#!/bin/bash


#How much days we save our files
DAYS_TO_KEEP_BACKUPS_ON_SERVER=7


#Get current directory of the script
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


FOLDER_LIST_FOR_CLEAN=$CURDIR/folders_for_clear.txt


while read -r line; 
do
    #safety check for empty strings in path
    $line = ${line##*( )}
    if [ "${#line}" -lt 5 ] || [ -z "$line" ] ; then
	    #echo "Skipping path: $line"
	    continue
    fi

    #Delete old files
    if [ "$DAYS_TO_KEEP_BACKUPS_ON_SERVER" -gt 0 ] ; then
	    find $line/* -type f -mtime +$DAYS_TO_KEEP_BACKUPS_ON_SERVER -exec rm {} \;
    fi

done < "$FOLDER_LIST_FOR_CLEAN"



