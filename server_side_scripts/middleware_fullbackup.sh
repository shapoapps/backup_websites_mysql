#!/bin/bash

#This command used for run desired bash script, or any bash command. From different linux user
sudo -H -u www-data bash -c 'cd /myscripts && ./fullbackup.sh '
