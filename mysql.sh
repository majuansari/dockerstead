#!/bin/bash
debconf-set-selections <<< "mysql-server mysql-server/root_password password 'secret'"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 'secret'"
apt-get install -y mysql-server

# Configure MySQL Password Lifetime

echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure MySQL Remote Access

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql --user="root"  -e "GRANT ALL ON *.* TO root@'0.0.0.0' WITH GRANT OPTION;"
service mysql restart

mysql --user="root"  -e "CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root"  -e "GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root"  -e "GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root"  -e "FLUSH PRIVILEGES;"
mysql --user="root"  -e "CREATE DATABASE homestead;"
service mysql restart

# Add Timezone Support To MySQL

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root mysql
