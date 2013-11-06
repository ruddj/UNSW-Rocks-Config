#!/bin/bash
passfile=~/ipmipass

if [ $# -ne 1 ] ; then
	echo "Only 1 argument [status|on|soft|off|toggle]"
	exit 1
fi

for i in {0..9} 
do
 echo "Compute-0-$i"
 ipmitool -I lan -H ipmi-0-$i.admin -f $passfile -U root chassis power $1 
done

for i in {0..5}
do
 echo "Compute-1-$i"
 ipmitool -I lan -H ipmi-1-$i.admin -f $passfile -U root chassis power $1
done

for i in {0..15}
do
 echo "Compute-2-$i"
 ipmitool -I lanplus -H ipmi-2-$i.admin -f $passfile -U root -C1 chassis power $1
done



