#!/bin/sh
/opt/passivedns/bin/passivedns -V
if [ $? -ne 0 ]; then 
	echo 'not a passivedns box !?'
	exit 1 
fi
apt-get -y -qq install curl
curl -sL https://deb.nodesource.com/setup | bash -
apt-get -y -qq install nodejs
node -v
npm -v

mkdir -p /opt/json2ela
cd /opt/json2ela
curl -k -s "https://gist.githubusercontent.com/hillar/4b014ba3abcc07a8c5c9/raw/364e6bfcab31ea914b4aaf3a5244ee5520dee4c6/json2elastic.js" -o json2elastic.js
npm install byline
node json2elastic.js

echo ""
echo "1) run passivedns"
echo "2) upload log to elastic with \"node /opt/json2elajson2elastic.js /var/log/passivedns.log 192.168.33.111:9200/passivedns/raw/ \""
