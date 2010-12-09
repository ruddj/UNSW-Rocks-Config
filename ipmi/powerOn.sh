#!/bin/bash
passfile=~ruddj/ipmipass

for i in {0..13} 
do
 echo "compute-1-$i"
 ipmitool -I lan -H manager-0-$i -f $passfile -U root chassis power on 
done

