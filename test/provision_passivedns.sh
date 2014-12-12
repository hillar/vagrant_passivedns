#!/bin/bash



/opt/passivedns/bin/passivedns -V
if [ $? -ne 0 ]; then 
	echo 'not a passivedns box !?'
	exit 1 
fi


#install golang
cd /tmp/
wget https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz
tar -xzf godeb-amd64.tar.gz 
gv=$(./godeb list| head -1)
./godeb install $gv
dpkg -i go_1.4-godeb1_amd64.deb
mv go_1.4-godeb1_amd64.deb /home/vagrant/
go version

#install heka
apt-get -y -qq install cmake mercurial
cd /tmp/
git clone https://github.com/mozilla-services/heka
cd heka/
source build.sh
make deb
dpkg -i heka_0.9.0_amd64.deb 
mv heka_0.9.0_amd64.deb /home/vagrant/
hekad -version

mkdir -p /opt/heka/etc
cd /opt/heka/etc
wget https://raw.githubusercontent.com/hillar/vagrant_passivedns/master/test/passivedns.toml
mkdir -p /opt/heka/lua
cd /opt/heka/lua
wget https://raw.githubusercontent.com/hillar/vagrant_passivedns/master/test/passivedns.cof.lua
wget https://raw.githubusercontent.com/hillar/vagrant_passivedns/master/test/json.lua

 


# install nodejs
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

# fill logs 

/opt/passivedns/bin/passivedns -j -J -P 1 -X 46CDNOPRSTMnfsxoryetaz -D

sleep 1

echo "wait, doing some digging to fill log ..."
isp=$(dig +noall +stats 2>&1 | awk '$2~/^SERVER:$/{split($3,dnsip,"#");print dnsip[1]}');
for i in "must.get.nxdomain" "youtube.com" "wikipedia.org";
do
    for z in "A" "AAAA" "MX" "CNAME" "NS" "PTR"  "SOA" "SPF" "SRV" "TXT";
    do
      echo  "$z $i";
      for j in "${isp}"  "8.8.8.8"  "4.2.2.2" "208.67.222.222" "156.154.70.1";
      do
        dig ${z} +noall +stats +time=9 @${j} ${i} 2>&1 > /dev/null;
      done
  done
done


kill $(cat /var/run/passivedns.pid)

wc -l /var/log/passivedns.*

#put tempalte
curl -s -XPUT http://192.168.33.111:9200/_template/passivedns -d'
{
  "template" : "passivedns",
  "settings" : {
    "index.refresh_interval" : "2s",
    "index.number_of_shards" : 1, 
    "index.number_of_replicas" : 0 
  },
  "mappings" : {
    "_default_" : {
       "_all" : {"enabled" : true},
       "dynamic_templates" : [ {
         "string_fields" : {
           "match" : "*",
           "match_mapping_type" : "string",
           "mapping" : {
             "type" : "string", "index" : "analyzed", "omit_norms" : true,
               "fields" : {
                 "raw" : {"type": "string", "index" : "not_analyzed", "ignore_above" : 256}
               }
           }
         }
       } ]
    }
  }
}
'

echo "uploading passivedns log to elasticsearch ..."
node /opt/json2ela/json2elastic.js /var/log/passivedns.log 192.168.33.111:9200/passivedns/raw/ 

sleep 3 

curl -s -XGET 'http://192.168.33.111:9200/passivedns/raw/_search?pretty' -d '
{
	"size": 0,
    "aggs" : {
        "class" : {
            "terms" : { "field" : "class" }
        },
         "type" : {
            "terms" : { "field" : "type" }
        }
    }
}
'

