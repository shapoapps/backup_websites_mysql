![alt text](https://github.com/shapoapps/assets/blob/master/very_small_banner1.jpg)
# bash script for backup sites and database :  

### Instruction on how to install, configure backup scripts.


[Russian documentation](https://github.com/shapoapps/backup_websites_mysql/blob/master/README_RU.md)

<br>

#### Default directory structure:<br>

#### Server side scripts
/myscripts/backup - directory for file backups<br>
/myscripts/backup_bd - directory to store database backups<br>
.../databases_to_backup.txt - file contain databases names for backup<br>
.../file_cleaner.sh - script to automatically delete files older than N days<br>
.../files_to_backup.txt - file contain directories paths for backup by script fullbackup.sh<br>
.../folders_for_clear.txt - file contain directories paths for file_cleaner.sh<br>
.../folders_skeleton.txt - file contains paths to directories that structure to be saved, without files names, recursive.<br>
.../fullbackup.sh - script for backup of directories and databases<br>
.../view_databases_name.sh - script to view the list of MySQL databases in the system<br>
.../middleware_fullbackup.sh - middleware to run the fullbackup.sh from name of another linux user<br>

<br> <br>

#### Storage side scripts
.../download_backups.sh - script to download backup files from your server<br>
.../downloadbackups.log - backup file download log<br>
<br><br>


<b>Fast install:</b><br>

On the VPS where you want create backups.<br>
Create folder ` /backups_server ` <br>
Create folder ` /myscripts/cron ` <br>
inside this folder run ` git clone https://github.com/shapoapps/backup_websites_mysql.git ` <br>
Create folder for local backup storage ` /backups_server ` <br>
Edit file ` /myscripts/cron/backup_websites_mysql/server_side_scripts/fullbackup.sh ` - enter your MySQL user and password <br>
Edit file ` /myscripts/cron/backup_websites_mysql/server_side_scripts/files_to_backup.txt ` - enter paths to folders you want backup <br>
In the console, type ` crontab -e `<br>
At the end of the file, add a line:<br>
` 0 3 * * * /myscripts/cron/backup_websites_mysql/server_side_scripts/fullbackup.sh ` <br>
save the cron file. Your server will now be backed up every day at 3 a.m. <br>



<br>
<br>
<b>Detailed info:</b>
<br>
<br>
<br>


<b>1. Install and configure the script fullbackup.sh</b><br>

Designed for use on a VPS server. Creates file and database archives.<br>

<b>Script settings:</b><br>

<b>MYSQLUSER</b> = username of the MySQL user who has read access to all databases that are going to be archived.<br>

<b>MYSQLPASSWORD</b> = the password of this user. <br>

<b>DAYS_TO_KEEP_BACKUPS_ON_SERVER</b>=7  number of days the created archives are stored on the server<br>

<b>DB_MODE_FLAG</b>=2 databases backup mode. If = 1, script take databases names from text file databases_to_backup.txt . 
If <> 1 then script backup all databases.<br>


<b>sites_array</b>=(/mysite1.com/ /mysite2.com/ /mysite3.com/)<br>
An array with site names, when reading a path for archiving, the script checks for a match with one of the names in that array,
If there is a match, a site name will be added to the file name, without the characters "/" . If the match
with site name not found, file will be named format: 26.12.19--08-48-29-undefined_site-backup.zip<br>


<b>FOLDERS</b>=$CURDIR/files_to_backup.txt<br>
The name of the backup directory file relative to the current directory.<br>


<b>DATABASES</b>=$CURDIR/databases_to_backup.txt<br>
File name with database names to back up. To quickly view the names of all databases in the system, use the view_databases_name.sh .<br>


<b>FOLDERS_STRUCTURE_TO_STORE</b>=$CURDIR/folders_skeleton.txt<br>
File name with paths to catalogs, which structure need to store. Files names not stores, only directorys, recursive.<br>


<b>ARCHIVED_FILES_FOLDER</b>=/backups_server<br>
Directory to store archived directories relative to the current directory.<br>


<b>ARCHIVED_DATABASES_FOLDER</b>=/backups_server<br>
Directory for storing archived database files relative to the current directory.<br>


<br>
For work of a script, there has to be an access to the catalog '/backups_server', - for record.<br>

Must be read access to the file directories. If you wants to run backup process from different cron user. 
Link cron to a middleware_fullbackup.sh in which you can specify linux user for backup process.<br>


In the databases_to_backup.txt file, enter the database names to back up, one name per row, as in the example.<br>

In the files_to_backup.txt file, enter the backup directory paths, one path per line, as in the example.<br>

Run the fullbackup.sh, if everything is configured correctly, after processing in the directory '/backups_server' - the archive files will appear.<br>

<br><br>

<b>2. Configure of a script file_cleaner.sh</b>

The script must have write access to the directories from which you want to delete files.<br>

The script deletes only files, not directories, and subdirectories.<br>

If you use cron, you can use a middleware to distinguish access rights, similar to middleware_fullbackup.sh<br>

Fill the directory paths to clean up in the - folders_for_clear.txt file, run the file_cleaner.sh script.
If all configured correctly,files older than N days will be deleted.<br>

<br><br>

<b>3. download_backups.sh script</b><br>

Destination to download backups from the server to storage using SSH protocol.<br>

Catalogs by default:<br>
` /backups_server ` - directory on remote server<br>
` /backups/files ` - directory on the local computer, to store backups<br>
<br>

./download_backups.sh - place at any directory with the right to write to it.<br>
./downloadbackups.log - place at same directory as download_backups.sh <br>

<br>

<b>Settings:</b><br>

<b>ARCHIVED_REMOTE_FOLDER_FILES</b>='/backups_server/'<br>
Path to the file backup directory on the remote server.<br>


<b>LOCAL_FILES_PATH</b>='/backups/my_development_server'<br>
The path to the directory where the file backups were received, on the local computer.<br>


<b>SSH_CONNECTION_NAME</b>='connection_to_my_vps'<br>
Name of the SSH connection in the system. Mandatory, between storage computer and server - SSH connection by keys must be configured.<br>

<br>

If all configured correct. After running the download_backups.sh script, the received files appear in the directories ` '/backups/my_development_server' ` .
Only new files are downloaded from the server. It is possible by analogy with middleware_fullbackup.sh - to organize work with cron through an middleware, from another
username.

<br><br>

<b>4. Configure SSH Connection by Name</b><br>

After setting up the connection from the storage computer, to our server by SSH keys.
We need to create a name for this connection.<br>

In the file/etc/ssh_config we add the following code block:<br>

` Host connection_to_my_vps ` - our connection SSH name<br>
` HostName 11.222.111.22`  - IP address of our server<br>
` ServerAliveInterval 50 ` - not changing<br>
` User aleks ` - user ssh name<br>
` PubKeyAuthentication yes ` - do not change<br>
` Port 22 ` - port on which the SSH service is located on the server, usually 22 <br>
` Protocol 2 ` - do not change <br>
` IdentityFile /home/user/.ssh/my_vps_server/ossh ` - path to private key file <br>


Important. Access rights to the ssh key file - must be 600, the owner of the key file and the user we run
script download_backups.sh - must be the same. Check if everything is configured correctly. <br>
In the console, when running under the user to whom the
ssh keys belong. Try to connect via ssh to our server it is enough to enter ` ssh connection_to_my_vps `, and there will be a connection, without any input of passwords.<br>
Not a small advantage is cryptographic-resistant encryption in such a method of connection, which allows to download backups automatically through
any kind of internet channel, including public access points. When creating a ssh key, it is better to select 4096 length.<br>
<br>
Rsync must be installed for successful operation (in most cases default in OS)

<br><br>

<b>Cron configuration to automatically start backups.</b><br>

On the VPS where you want create backups.<br>

In the console, type ` crontab -e `<br>
At the end of the file, add a line:<br>
` 0 3 * * * /myscripts/cron/backup_websites_mysql/server_side_scripts/fullbackup.sh ` <br>
save the cron file. Your server will now be backed up every day at 3 a.m. <br>

<b>middleware_fullbackup.sh</b> - script to run the fullbackup.sh as the user you want<br>



