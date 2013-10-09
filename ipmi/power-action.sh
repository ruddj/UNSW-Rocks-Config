#!/bin/bash
passfile=~ruddj/ipmipass

for i in {0..13}
do
 echo "compute-1-$i"
  ipmitool -I lan -H ipmi-1-$i.ipmi -f $passfile -U root chassis power $1
done

for i in {0..6}
do
 echo "Compute-2-$i"
 ipmitool -I lanplus -H ipmi-2-$i.ipmi -f $passfile -U root chassis power $1
done

