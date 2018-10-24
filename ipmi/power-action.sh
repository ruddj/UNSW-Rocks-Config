#!/bin/bash
passfile=~ruddj/ipmipass

# FC630
for j in {0..2}
do
  for i in {0..3}
  do
   echo "abacusc-$j-$i"
   ipmitool -I lan -H abacusc-$j-$i-oob.imdc.unsw.edu.au -f $passfile -U root chassis power $1
  done
done

# FC430
for i in {0..7}
do
 echo "abacusc-3-$i"
 ipmitool -I lanplus -H abacusc-3-$i-oob.imdc.unsw.edu.au -f $passfile -U root chassis power $1
done

