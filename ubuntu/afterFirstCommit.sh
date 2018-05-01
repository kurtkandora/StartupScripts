NAMEOFYOURAPP="[NAMEOFYOURAPP]"


sudo chown -R :www-data /var/www/$NAMEOFYOURAPP
sudo chmod -R 775 /var/www/$NAMEOFYOURAPP/storage
sudo chmod -R 775 /var/www/$NAMEOFYOURAPP/bootstrap/cache
