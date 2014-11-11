#!/bin/sh
echo "setting up elasticsearch .."
apt-get -y -qq install curl
curl -s http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
echo "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main" > /etc/apt/sources.list.d/elasticsearch.list
apt-get -y -qq update 
echo "installing java.."
apt-get -y -qq install openjdk-7-jdk
echo "installing elastic"
apt-get -y -qq install elasticsearch
update-rc.d elasticsearch defaults 95 10
/etc/init.d/elasticsearch start
echo "done, you should get :: \"status\" : 200, ......"
sleep 3

curl -s http://localhost:9200/
curl -s http://localhost:9200/_cat/health?v
