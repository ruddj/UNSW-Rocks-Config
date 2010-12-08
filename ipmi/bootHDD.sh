#!/bin/bash
passfile=~ruddj/ipmipass

for i in {0..13} 
do
 echo "Dell-0-$i"
 ipmitool -I lan -H manager-0-$i -f $passfile -U root bootdev disk  
done

