#!/usr/bin/env bash
MYSQLPASSWORD="[MYSQLPASSWORD]"
DATABASENAME="[DATABASENAME]"
YOURDOMAIN="[YOURDOMAIN]"
NAMEOFYOURAPP="[NAMEOFYOURAPP]"

# Update Package List

apt-get update -y

# Update System Packages
apt-get upgrade -y

sudo apt-get install zip unzip curl nginx -y

echo "mysql-server mysql-server/root_password password $MYSQLPASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQLPASSWORD" | debconf-set-selections
apt-get install -y mysql-server

# making mysql secure #

# Kill the anonymous users
mysql -u root --password=$MYSQLPASSWORD -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic to kill hostname users
mysql -u root --password=$MYSQLPASSWORD -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -u root --password=$MYSQLPASSWORD -e "DROP DATABASE test"
# Make our changes take effect
mysql -u root --password=$MYSQLPASSWORD -e "FLUSH PRIVILEGES"

# Install PHP Stuffs

# PHP 7.1
apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
php7.1-fpm \
php7.1-gd php7.1-mcrypt \
php7.1-curl php7.1-memcached \
php7.1-imap php7.1-mysql php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline

phpenmod mcrypt
phpenmod mbstring
phpenmod curl

# PHP Configuration

sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/7.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini

sudo systemctl restart php7.1-fpm

# Nginx config

sed -i "s/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm;/" /etc/nginx/sites-available/default
sed -i "s/server_name _;/server_name $YOURDOMAIN;/" /etc/nginx/sites-available/default
sed -i "s/#location ~ /location ~ /" /etc/nginx/sites-available/default
sed -i "s?#\sinclude snippets/f?       include snippets/f?" /etc/nginx/sites-available/default
sed -i "s?#[ \t\s\n]*include snippets/f?       include snippets/f?" /etc/nginx/sites-available/default
sed -i "s/#\sfastcgi_pass unix/       fastcgi_pass unix/" /etc/nginx/sites-available/default
sed -i "s/7.0/7.1/" /etc/nginx/sites-available/default
sed -i "s/.sock;/.sock;\n\t}/" /etc/nginx/sites-available/default
sed -i "s/#\sdeny all;/\tdeny all;\n\t}/" /etc/nginx/sites-available/default

systemctl reload nginx

sudo mkdir -p /var/www/$NAMEOFYOURAPP
sudo sed -i "s/html;/$NAMEOFYOURAPP\/public;/" /etc/nginx/sites-available/default
sed -i "s/=404;/\/index.php?\$query_string;/" /etc/nginx/sites-available/default

service nginx restart

# Installing Composer

cd ~
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# setting Git

cd /var
mkdir repo && cd repo
mkdir $NAMEOFYOURAPP.git && cd $NAMEOFYOURAPP.git
git init --bare
cd hooks
echo "#!/bin/sh" > post-receive
echo "git --work-tree=/var/www/$NAMEOFYOURAPP --git-dir=/var/repo/$NAMEOFYOURAPP.git checkout -f" >> post-receive
sudo chmod +x post-receive

# Create Database

mysql -u root --password=$MYSQLPASSWORD -e "CREATE DATABASE $DATABASENAME"

$ Firewall

ufw allow in "Nginx Full"
ufw allow 22
ufw allow 80
ufw allow 443


