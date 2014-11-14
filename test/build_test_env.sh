#!/bin/sh

# this script will
# * build debian box with passivedns
# * set up multimachine vagrant with
#  - passivedns
#  - elsticsearch
#  - TODO https://tools.ietf.org/id/draft-dulaunoy-kaplan-passive-dns-cof-02.txt REST server
# optional: wipes old build



# by default debian 7.7 is used for boxes
BOXDIR=../boxes/debian/debian-7.7
BOXFILE=passivedns.box
WIPE=0

while :
do
  case $1 in
    --wipe)
    WIPE=1
    shift
    ;;
  -d | --dir)
    BOXDIR=$2
    shift 2
    ;;
  -*)
    echo "Unknown option '$1'"
    echo ""
    echo "usage : $0 --dir ../boxes/some/dir/you/have/boxes"
    exit 1
    ;;
  *)
    echo "using default option for box dir :: $BOXDIR"
    echo ""
    break
    ;;
  esac
done

if [ $WIPE -eq 1 ]; then
	if [ -f "$BOXDIR/$BOXFILE" ]; then
		echo "deleting $BOXDIR/$BOXFILE";
		rm "$BOXDIR/$BOXFILE";
		echo "destroying box $BOXDIR"
		(cd "$BOXDIR"; vagrant destroy -f;)
		echo "destroying all other.."
		vagrant destroy -f;
	fi
fi


#check for box, build if needed
if [ ! -f "$BOXDIR/$BOXFILE" ]; then
	echo "building passivedns box $BOXDIR/$BOXFILE, may take some time .. "
	(cd $BOXDIR; time vagrant up; vagrant halt; time vagrant package --output $BOXFILE;)
fi
if [ ! -f "$BOXDIR/$BOXFILE" ]; then
	echo "failed with $BOXDIR/$BOXFILE"
	exit 1
fi

echo "setting vagrant to use $BOXDIR/$BOXFILE"

#find out base box
BASEBOX=$(grep "config.vm.box" $BOXDIR/Vagrantfile | rev | cut -f1 -d" "| rev | sed 's/"//g')

sed -i -e "s,\$BOX = .*,\$BOX = '${BASEBOX}'," Vagrantfile
sed -i -e "s,\$PDNSBOX = .*,\$PDNSBOX = '${BOXDIR}/${BOXFILE}'," Vagrantfile

vagrant status
if [ $? -ne 0 ]; then 
	echo 'vagrant file broken !?'
	exit 1 
fi

time vagrant up
vagrant status

echo "done, now you can do \"vagrant ssh passivedns\""
