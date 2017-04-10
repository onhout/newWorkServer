#!/bin/bash

#helpers
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

function setup_computer() {
				#add repos
				sudo add-apt-repository -y ppa:ondrej/php
				sudo curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

				#update
				sudo apt-get -y --force-yes update
				sudo apt-get -y --force-yes upgrade

				#installation
				sudo apt-get install -y gawk subversion nodejs build-essential unzip apache2 smarty checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev python-pip

				#install composer
				sudo curl -sS https://getcomposer.org/installer | php
				sudo mv composer.phar /usr/local/bin/composer
				sudo chmod 755 /usr/local/bin/composer

				#install python
				cd /usr/src
				sudo wget https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz
				sudo tar xzf Python-3.5.2.tgz
				cd Python-3.5.2
				sudo ./configure
				sudo make install

				#install django
				cd $HOME
				sudo pip3 install --upgrade pip
				sudo pip3 install virtualenv django simplejson requests Jinja2

				#fix npm permission
				nodeprefix=`npm config get prefix`
				if [ $nodeprefix = "/usr/local" ]; then
					sudo chown -R $(whoami) $($nodeprefix)/{lib/node_modules,bin,share}
				elif [ $nodeprefix = "/usr" ]; then
					mkdir $HOME"/.npm-global"
					npm config set prefix $HOME'/.npm-global'
					export PATH=$HOME/.npm-global/bin:$PATH
					source $HOME/.profile
				fi

				npm install -g bower gulp-cli socket.io request babel

				#write hosts, extra stuff is to spawn another process to able to write
				sudo -- sh -c "echo 192.168.50.233	prop-db-active >> /etc/hosts"
				sudo -- sh -c "echo 192.168.120.253	active-directory >> /etc/hosts"

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

				sudo cp mypropdev.mkainc.com.conf /etc/apache2/sites-available
				sudo a2ensite mypropdev.mkainc.com.conf
				sudo cp mypreproduction.mkainc.com.conf /etc/apache2/sites-available
				sudo a2ensite mypreproduction.mkainc.com.conf
				sudo cp myproplive.mkainc.com.conf /etc/apache2/sites-available
				sudo a2ensite myproplive.mkainc.com.conf

				sudo service apache2 restart

				echo "***********"
				echo "**RESTART**"
				echo "**COMPUTER*"
				echo "***********"
}
#adding propdev
function get_new_branch() {
				echo "ENTER YOUR PROPDEV BRANCH NAME:"

				read branchName

				sudo rm -rf /var/www/propdev
				sudo mkdir /var/www/propdev
				sudo chmod 777 -R $_
				cd $_
				sudo svn checkout http://svn.mkainc.com:11411/repos/Branches/gliu/$branchName/ . --username=gliu --password=%Password1
				php composer.phar install
				npm install
				cd ..
				sudo chmod 777 -R propdev
                                cd propdev
                                gulp prepForDeployment
}

function get_all_branches() {
				sudo rm -rf /var/www/preproduction
				sudo mkdir /var/www/preproduction
				sudo chmod 777 -R $_
				cd $_
				sudo svn checkout http://svn.mkainc.com:11411/repos/Branches/prop_preproduction/web/ . --username=gliu --password=%Password1
				php composer.phar install
				npm install
				cd ..
				sudo chmod 777 -R propdev

				sudo rm -rf /var/www/live
				sudo mkdir /var/www/live
				sudo chmod 777 -R $_
				cd $_
				sudo svn checkout http://svn.mkainc.com:11411/repos/prop/web/ . --username=gliu --password=%Password1
				php composer.phar install
				npm install
				cd ..
				sudo chmod 777 -R propdev
}

function merge_preproduction() {
				cd /var/www/propdev
				sudo svn update
				sudo svn merge http://svn.mkainc.com:11411/repos/Branches/prop_preproduction/web/ --username=gliu --password=%Password1 --accept=theirs-full
                                svn status | grep '?' | sed 's/^.* /svn add /' | bash
				sudo svn commit -m "Merged with preproduction"
}


function setup_new_branch(){
    echo "Enter New Branch Name:"
    read branchName
    sudo svn copy http://svn.mkainc.com:11411/repos/Branches/prop_preproduction/web/ --username=gliu --password=%Password1 -m "Copy from Preproduction" http://svn.mkainc.com:11411/repos/Branches/gliu/$branchName
}


PS3='Please enter your choice: '
options=("Set Up Server" "Checkout Branch" "Merge to Preproduction" "Get All Branches" "Copy Working Copy of Preproduction" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Set Up Server")
            setup_computer
            break
            ;;
        "Checkout Branch")
            get_new_branch
            break
            ;;
        "Merge to Preproduction")
            merge_preproduction
            break
            ;;
        "Get All Branches")
            get_all_branches
            break
            ;;
        "Copy Working Copy of Preproduction")
            setup_new_branch
            break
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
