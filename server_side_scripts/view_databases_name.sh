#!/bin/bash

#Script for view available databases

MYSQLUSER='mysql_user'
MYSQLPASSWORD='password'


echo `mysql -u $MYSQLUSER -p$MYSQLPASSWORD -e "SHOW DATABASES;" | tr -d "|" | grep -v Database`

