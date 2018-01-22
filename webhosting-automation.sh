#!/bin/bash

sitedir=/projects

a=$1
MSP=mysqlpassword

echo "Starting process for $a"
echo "-----------------------"
echo "copying template file to /etc/apache2/sites-available and making changes"

#creating apache files for site

cp /templates/website.template /etc/apache2/sites-available/$a
sed -i "s/website/$a/g" /etc/apache2/sites-available/$a
ln -s /etc/apache2/sites-available/$a /etc/apache2/sites-enabled/$a



# creating a db

db=$( echo $a | tr '.' 'aa' | cut -c 1-6)
echo "creating db $db for $a, Also creating user and assigning permissions on db"
mysql -u root -p$MSP -e "create user '$db'@'localhost' "
mysql -u root -p$MSP -e "create database $db"

dbpass=$( pwgen -cB1 )
mysql -u root -p$MSP -e "grant all privileges on $db.* to '$db'@'localhost' identified by '$dbpass' "

#Creating Sites and copying wordpress files

echo "db created for $a with name: $db with pass: $dbpass" >> dbdetails
mkdir /$sitedir/$a
mkdir /$sitedir/$a/htdocs
mkdir /$sitedir/$a/logs
mkdir /$sitedir/$a/cgi-bin

cp -r /templates/wordpress/. /$sitedir/$a/htdocs
cp /$sitedir/$a/htdocs/wp-config-sample.php /$sitedir/$a/htdocs/wp-config.php

sed -i "s/database_name_here/$db/g" /$sitedir/$a/htdocs/wp-config.php
sed -i "s/username_here/$db/g" /$sitedir/$a/htdocs/wp-config.php
sed -i "s/password_here/$dbpass/g" /$sitedir/$a/htdocs/wp-config.php

chown -R www-data:www-data /$sitedir/$a/


#creating user and FTP
useradd -d /$sitedir/$a $db
ftppass=$( pwgen -cB1 )

echo "$db:$ftppass" | chpasswd

echo "changing owner and group of /$sitedir/$a/htdocs to $db:www-data"

chown -R $db:www-data /$sitedir/$a/htdocs


#Generating report

echo "                                                                " >> Details
echo "------------------------------------------------------------------------------------------------------------------------------" >> Details
echo "Site        DBname        DBuser        DBPass        FTPUser        FTPPass                    " >> Details
echo "-------------------------------------------------------------------------------------------------------------------------------" >> Details
echo "$a        $db        $db        $dbpass        $db        $ftppass                " >> Details
echo "--------------------------------------------------------------------------------------------------------------------------------" >> Details