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

# fill logs 

/opt/passivedns/bin/passivedns -j -J -P 1

#!/bin/bash
isp=$(dig +noall +stats 2>&1 | awk '$2~/^SERVER:$/{split($3,dnsip,"#");print dnsip[1]}');
m="-------------------------------------------------------------------------------";
s="                                                                               ";
h="+${m:0:25}+${m:0:12}+${m:0:12}+${m:0:12}+${m:0:12}+${m:0:12}+";
header=("Domain${s:0:23}" "Your ISP${s:0:10}" "Google${s:0:10}" "4.2.2.2${s:0:10}" "OpenDNS${s:0:10}" "DNS Adv.${s:0:10}");
echo "${h}";
echo "| ${header[0]:0:23} | ${header[1]:0:10} | ${header[2]:0:10} | ${header[3]:0:10} | ${header[4]:0:10} | ${header[5]:0:10} |";
echo "${h}";
for i in "bbc.co.uk" "lifehacker.com" "nytimes.com"  "youtube.com" "wikipedia.org";
do
    for z in "A" "AAAA" "MX" "CNAME" "NS" "PTR"  "SOA" "SPF" "SRV" "TXT";
    do
        ii="${z} ${i}${s:23}";

      echo -ne "| ${ii:0:23} |";

      for j in "${isp}"  "8.8.8.8"  "4.2.2.2" "208.67.222.222" "156.154.70.1";
      do
        r="${s:10}$(dig ${z} +noall +stats +time=9 @${j} ${i} 2>&1 | awk '$2~/^Query$/{print $4" "$5}')";
        echo -ne " ${r:${#r}-10} |";
      done
      echo -ne "\n${h}\n";
  done
done




echo ""
echo "1) run passivedns"
echo "2) upload log to elastic with \"node /opt/json2elajson2elastic.js /var/log/passivedns.log 192.168.33.111:9200/passivedns/raw/ \""
