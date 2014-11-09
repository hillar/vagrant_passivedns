#!/bin/sh

# This script will 
# * use apt-get/yum to install OS dependancies
# * download known working versions of passivedns dependancies
# * build them statically 
# * configure passivedns to use them
# * build passivedns

PCAP=1.5.3
PFRING=5.6.1
LDNS=1.6.17
JANSSON=2.7

TDIR="/opt/passivedns"
TEMPDIR="/opt/passivedns/deleteme"
DOPFRING=0

while :
do
  case $1 in
  -p | --pf_ring | --pfring)
    DOPFRING=1
    shift
    ;;
  -d | --dir)
    TDIR=$2
    shift 2
    ;;
  -*)
    echo "Unknown option '$1'"
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

# Installing dependencies
echo "PASSIVEDNS: Installing Dependencies"
if [ -f "/etc/redhat-release" ]; then
  # TODO
  yum -y install wget git
  if [ $? -ne 0 ]; then
    echo "PASSIVENDS - yum failed"
    exit 1
  fi
fi

if [ -f "/etc/debian_version" ]; then
  apt-get -y -qq install wget git-core binutils-dev autoconf g++ flex build-essential bison libtool
  if [ $? -ne 0 ]; then
    echo "PASSIVEDNS - apt-get failed"
    exit 1
  fi
fi


echo "PASSIVEDNS: Building directory is $TEMPDIR"
if [ ! -d "$TEMPDIR" ]; then
  mkdir -p $TEMPDIR
fi
cd $TEMPDIR


echo "PASSIVEDNS: Downloading and building static thirdparty libraries"
if [ ! -d "thirdparty" ]; then
  mkdir thirdparty
fi
cd thirdparty

if [ $DOPFRING -eq 1 ]; then
    # pfring
    echo "PASSIVEDNS: Building libpcap with pfring";
    if [ ! -f "PF_RING-$PFRING.tar.gz" ]; then
      wget -q -O PF_RING-$PFRING.tar.gz http://sourceforge.net/projects/ntop/files/PF_RING/PF_RING-$PFRING.tar.gz/download
    fi
    tar zxf PF_RING-$PFRING.tar.gz
    (cd PF_RING-$PFRING; make)

    PFRINGDIR=`pwd`/PF_RING-$PFRING
    PCAPDIR=$PFRINGDIR/userland/libpcap
else
    echo "PASSIVEDNS: Building libpcap without pfring";
    # libpcap
    if [ ! -f "libpcap-$PCAP.tar.gz" ]; then
      wget -q http://www.tcpdump.org/release/libpcap-$PCAP.tar.gz
    fi
    tar zxf libpcap-$PCAP.tar.gz
    (cd libpcap-$PCAP; ./configure --quiet --disable-dbus; make --quiet)
    PCAPDIR=`pwd`/libpcap-$PCAP
fi

echo "PASSIVEDNS: Building ldns";
# ldns
if [ ! -f "ldns-$LDNS.tar.gz" ]; then
  wget -q http://www.nlnetlabs.nl/downloads/ldns/ldns-$LDNS.tar.gz
fi
tar zxf ldns-$LDNS.tar.gz
# ! without-ssl
(cd ldns-$LDNS; ./configure --quiet --enable-static --disable-shared --without-pyldnsx --without-ssl --disable-sha2  --disable-gost --disable-ecdsa --disable-dane; make --quiet)
LDNSDIR=`pwd`/ldns-$LDNS


echo "PASSIVEDNS: Building jansson";
# jansson
if [ ! -f "jansson-$JANSSON.tar.gz" ]; then
  wget -q http://www.digip.org/jansson/releases/jansson-$JANSSON.tar.gz
fi
tar zxf jansson-$JANSSON.tar.gz
# ! without-ssl
(cd jansson-$JANSSON; ./configure --quiet --enable-static --disable-shared ; make --quiet)
JANSSONDIR=`pwd`/jansson-$JANSSON

# Now build passivedns
echo "PASSIVEDNS: Building passivedns"
cd ..

git clone git://github.com/gamelinux/passivedns.git
cd passivedns/
# TODO 'fix' autoconf ver in config.ac

autoreconf --install
if [ $? -ne 0 ]; then
    echo "PASSIVEDNS - autoreconf failed, will try again with installed version"
    # try to get verion
    autoreconf_version=$(autoreconf -V | grep autoreconf | rev | cut -f1 -d" " | rev)
    # change version in configure.ac
    sed -i -e "s,AC_PREREQ(\[2\...\]),AC_PREREQ(\[${autoreconf_version}\]),g" configure.ac
    # try again
    autoreconf --install
    if [ $? -ne 0 ]; then
      echo " autoreconf failed, version $autoreconf_version"
      exit 1
    else
       echo "PASSIVEDNS - autoreconf with version $autoreconf_version"
    fi
fi



./configure --quiet LDFLAGS=-static --prefix=$TDIR --with-libpcap-includes=$PCAPDIR --with-libpcap-libraries=$PCAPDIR --with-ldns-includes=$LDNSDIR --with-ldns-libraries=$LDNSDIR/.libs  --with-jansson-includes=$JANSSONDIR/src --with-jansson-libraries=$JANSSONDIR/src/.libs --enable-json


make --quiet
#todo fix warnings ...
mkdir -p $TDIR/bin
cp src/passivedns $TDIR/bin

/opt/passivedns/bin/passivedns -V


