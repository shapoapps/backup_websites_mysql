#!/bin/bash


ARCHIVED_REMOTE_FOLDER_FILES='/myscripts/backup/'
ARCHIVED_REMOTE_FOLDER_DATABASES='/myscripts/backup_bd/'

LOCAL_FILES_PATH='/backups/files'
LOCAL_DATABASES_PATH='/backups/databases'

SSH_CONNECTION_NAME='connection_to_my_vps'

CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
date=$(date +"%d.%m.%y--%H-%M-%S")

if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
    #Internet is up, downloading backups from our servers

    rsync -avh -e ssh $SSH_CONNECTION_NAME:$ARCHIVED_REMOTE_FOLDER_FILES $LOCAL_FILES_PATH
    rsync -avh -e ssh $SSH_CONNECTION_NAME:$ARCHIVED_REMOTE_FOLDER_DATABASES $LOCAL_DATABASES_PATH

    echo "" >> $CURDIR/downloadbackups.log
    echo "Internet is up, downloading backups $date" >> $CURDIR/downloadbackups.log

else
    echo "" >> $CURDIR/downloadbackups.log
    echo "Internet is down, cant download backups $date" >> $CURDIR/downloadbackups.log
fi
