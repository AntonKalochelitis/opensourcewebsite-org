#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Configure timezone"
timedatectl set-timezone ${timezone} --no-ask-password

#info "Add MariaDB reposytory"
#apt-get install software-properties-common
#apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
#add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"

#info "Prepare root password for MariaDB"
#debconf-set-selections <<< "mariadb-server-10.4 mysql-server/root_password password \"''\""
#debconf-set-selections <<< "mariadb-server-10.4 mysql-server/root_password_again password \"''\""
#echo "Done!"

info "Prepare root password for MySQL"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
echo "Done!"

info "Add PHP 7.* reposytory"
add-apt-repository ppa:ondrej/php -y

info "Update OS software"
apt-get update
apt-get upgrade -y

info "Install additional software"
apt-get install -y mc
apt-get install -y php7.2 php7.2-curl php7.2-cli php7.2-intl php7.2-mysqlnd php7.2-gd php7.2-mbstring php7.2-xml php7.2-bcmath php7.2-bz2 php7.2-cgi php7.2-common php7.2-dba php7.2-dev php7.2-enchant php7.2-gmp php7.2-imap php7.2-interbase php7.2-json php7.2-ldap php7.2-mysql php7.2-odbc php7.2-opcache php7.2-pgsql php7.2-phpdbg php7.2-pspell php7.2-readline php7.2-recode php7.2-snmp php7.2-soap php7.2-sqlite3 php7.2-sybase php7.2-tidy php7.2-xmlrpc php7.2-zip php7.2-xsl
apt-get install -y php7.3 php7.3-curl php7.3-cli php7.3-intl php7.3-mysqlnd php7.3-gd php7.3-mbstring php7.3-xml php7.3-bcmath php7.3-bz2 php7.3-cgi php7.3-common php7.3-dba php7.3-dev php7.3-enchant php7.3-gmp php7.3-imap php7.3-interbase php7.3-json php7.3-ldap php7.3-mysql php7.3-odbc php7.3-opcache php7.3-pgsql php7.3-phpdbg php7.3-pspell php7.3-readline php7.3-recode php7.3-snmp php7.3-soap php7.3-sqlite3 php7.3-sybase php7.3-tidy php7.3-xmlrpc php7.3-zip php7.3-xsl
apt-get install -y php7.2-fpm
apt-get install -y php-mysql php-memcached memcached php.xdebug php-memcache php-mcrypt php-cli php-gd php-curl php-soap php-json php-xml php-zip php-mbstring php-bz2 php-snmp
apt-get install -y unzip nginx php.xdebug

info "Install Apache2-mpm-itk"
apt-get install -y apache2 libapache2-mpm-itk
apt-get install -y php libapache2-mod-php7.2
sed -i "s/Listen 80/Listen 81/g" /etc/apache2/ports.conf
ln -s /app/vagrant/apache2/opensourcewebsite.local.conf /etc/apache2/sites-enabled/opensourcewebsite.local.conf
a2enmod rewrite
/etc/init.d/apache2 restart

info "Configure PHP-FPM"
sed -i 's/user = www-data/user = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
cat << EOF > /etc/php/7.2/mods-available/xdebug.ini
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_autostart=1
EOF
echo "Done!"

info "Configure NGINX"
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

info "Enabling site configuration"
ln -s /app/vagrant/nginx/app.conf /etc/nginx/sites-enabled/app.conf
echo "Done!"

info "Configure MySQL"
apt-get install -y mysql-server-5.7 mysql-client-5.7
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
mysql -uroot <<< "FLUSH PRIVILEGES"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot <<< "FLUSH PRIVILEGES"
mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"

#info "Configure MariaDB"
#apt-get install -y mariadb-server-10.4 mariadb-client-10.4
#sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
#mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
#mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
#mysql -uroot <<< "DROP USER 'root'@'localhost'"
#mysql -uroot <<< "FLUSH PRIVILEGES"
#echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE osw"
mysql -uroot <<< "ALTER DATABASE `osw` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -uroot <<< "CREATE DATABASE osw_test"
mysql -uroot <<< "ALTER DATABASE `osw_test` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer