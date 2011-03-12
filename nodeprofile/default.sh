#!/bin/sh
echo "Setup Default.Route"
echo "-M- 800MB" > /gaussian/g03/Default.Route
echo "-P- 4" >> /gaussian/g03/Default.Route
#echo "-#- MaxDisk=20GW" >> /gaussian/g03/Default.Route
echo "-#- Int=FMMNAtoms=50000" >> /gaussian/g03/Default.Route
echo -n "-S- PVGauss_" >> /gaussian/g03/Default.Route
hostname -s >> /gaussian/g03/Default.Route
echo "" >> /gaussian/g03/Default.Route
cd /gaussian/g03/;./bsd/install

echo "Setup Local Partition. Checking permisions"
chgrp -R users /state/partition2/gauss
chmod -R 2775 /state/partition2/gauss
#chmod -R g+s /mydata

# should add cleanup to delete old files

#For each directory find most recent file

OLDTIME=15

#if [ $(find /protected/folder -atime -5 | wc -l) -eq 0 ]; then rm -r /protected/folder ; fi

echo "Checking for old folders"

for chkDir in $(find /state/partition2/*.* -type d) 
do
  if [ $(find $chkDir -mtime -$OLDTIME | wc -l) -eq 0 ]
   then 
     echo "Deleting $chkDir from `hostname`" >&2
     rm -r $chkDir 
  fi
done
