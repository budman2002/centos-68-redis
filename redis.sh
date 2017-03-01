#!/bin/sh
set -e

## redis.sh setups redis storage on xfs and redis-server
## Depends on:
## The expect package is installed
## Environment vars: REDIS_PORT

echo "Resizing logical volume for redis"

# Total Extends 
TOTAL=`vgdisplay | grep 'Total PE'`

# current extends of lv_root
CLE=`lvdisplay /dev/VolGroup/lv_root | grep "Current LE"`
WITHOUT_ROOT=$(expr ${TOTAL## * } - ${CLE## * })
TARGET=$(expr $WITHOUT_ROOT / 2 - 1)
echo "Resizing to $TARGET Extends"
lvextend -l $TARGET /dev/VolGroup/lv_varlibredis
echo "-------------------------------------------"
echo "Adjusting size of the filesystem"
xfs_growfs -d /dev/VolGroup/lv_varlibredis
echo "--------------------------------"


##echo "Adding mongodb.org's repository to /etc/yum.repos.d"
##cat << 'EOF' > /etc/yum.repos.d/mongodb-org-3.4.repo
##[mongodb-org-3.4]
##name=MongoDB Repository
##baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
##gpgcheck=1
##enabled=1
##gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
##EOF
##echo "---------------------------------------------------"
echo "Making EPEL repository available"
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
echo "--------------------------------"

# this is surely better done using chef recipes, but for recorded hostory sake
# Prerequisites: gcc and kernal headers and tcl expect

# 1) download the approved (local) or latest redis server source (global - wget http://download.redis.io/redis-stable.tar.gz)
cd ~vagrant
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make && make test && make install

# 3) run the install script via expect - accept all defaults except redis-server executable location: /usr/local/bin/redis-server
#Please select the redis port for this instance: [6379] 
#Selecting default: 6379
#Please select the redis config file name [/etc/redis/6379.conf] 
#Selected default - /etc/redis/6379.conf
#Please select the redis log file name [/var/log/redis_6379.log] 
#Selected default - /var/log/redis_6379.log
#Please select the data directory for this instance [/var/lib/redis/6379] 
#Please select the redis executable path [] /usr/local/bin/redis-server
#Selected config:
#Port           : 6379
#Config file    : /etc/redis/6379.conf
#Log file       : /var/log/redis_6379.log
#Data dir       : /var/redis/6379
#Executable     : /usr/local/bin/redis-server
#Cli Executable : /usr/local/bin/redis-cli
#Is this ok? Then press ENTER to go on or Ctrl-C to abort.
#Copied /tmp/6379.conf => /etc/init.d/redis_6379
#Installing service...
#Successfully added to chkconfig!
#Successfully added to runlevels 345!
#Starting Redis server...
#Installation successful!

echo "make redis a service"
cd utils
expect  <<EOF 
spawn ./install_server.sh
set timeout 1
expect '$'
send $REDIS_PORT\r
expect '$'
send \r
expect '$'
send \r
expect '$'
send \r
expect '$'
send /usr/local/bin/redis-server\r
expect '$'
send \r
expect 'Installation successful!'
EOF

echo "--------------------------------"

