#!/bin/bash

for i in {0..15}
do
 echo "Compute-2-$i"
 IBMAC=`ssh -q compute-2-$i  "ip addr show ib0 | grep infiniband | xargs echo | cut -d' ' -f2"`
 IBROCKS=`rocks list host interface compute-2-$i | grep ib0 | awk '{print $3}'`

 if [[ ! -z $IBMAC ]] ; then
  if [[ "$IBMAC" != "$IBROCKS" ]] ; then
   echo "Settings IB MAC to $IBMAC"
   /opt/rocks/bin/rocks set host interface mac compute-2-$i ib0 $IBMAC 
   /opt/rocks/bin/rocks sync host network compute-2-$i
  fi
 else
  echo "Could not find IB MAC"
 fi
done

