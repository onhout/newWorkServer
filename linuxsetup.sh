#!/bin/bash

#helpers
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

#add repos
sudo add-apt-repository -y ppa:ondrej/php
sudo curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

#update
sudo apt-get -y --force-yes update
sudo apt-get -y --force-yes upgrade

#installation
sudo apt-get install -y gawk subversion nodejs build-essential

#install composer
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod 755 /usr/local/bin/composer

#fix npm permission
nodeprefix=`npm config get prefix`
if [ $nodeprefix = "/usr/local" ]; then
	sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
elif [ $nodeprefix = "/usr" ]; then
	mkdir $HOME"/.npm-global"
	npm config set prefix '~/.npm-global'
	export PATH=$HOME/.npm-global/bin:$PATH
	source ~/.profile
fi
npm install -g bower

#write hosts
sudo su
sudo echo "192.168.50.233	prop-db-active" >> /etc/hosts
sudo echo "192.168.120.253	active-directory" >> /etc/hosts
exit

#test php version
php56version=5.6
phpver=`php -v |grep -Eow '^PHP [^ ]+' |gawk '{ print $2 }'`

#install php
if version_gt $php56version $phpver; then
     echo "$php56version is greater than installed version! ($phpver)!"
     echo "installing PHP$php56version..."
     sudo apt-get install -y php5.6 php5.6-cli php5.6-common php5.6-curl php5.6-dev php5.6-gd php5.6-intl php5.6-json php5.6-ldap php5.6-mbstring php5.6-mcrypt php5.6-memcache php5.6-memcached php5.6-mysql php5.6-pgsql php5.6-readline php5.6-sqlite php5.6-xml php5.6-xsl libzip4 php5.6-zip libapache2-mod-php5
     sudo a2dismod php5.5
     sudo a2enmod php5.6
     sudo service apache2 restart
fi

echo "ENTER YOUR PROPDEV BRANCH NAME:"

read branchName

sudo rm -rf /var/www/propdev
sudo mkdir /var/www/propdev
sudo chmod 777 -R $_
cd $_
sudo svn checkout http://ec2-54-83-225-157.compute-1.amazonaws.com:11411/repos/Branches/gliu/$branchNa$
php composer.phar install
npm install
cd ..
sudo chmod 777 -R propdev
