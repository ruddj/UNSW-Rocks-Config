#!/bin/bash
passfile=~ruddj/ipmipass

for i in {0..13} 
do
 echo "Compute-1-$i"
 ipmitool -I lan -H ipmi-1-$i.ipmi -f $passfile -U root chassis power status  
done

for i in {0..6}
do
 echo "Compute-2-$i"
 ipmitool -I lan -H ipmi-2-$i.ipmi -f $passfile -U root chassis power status
done

