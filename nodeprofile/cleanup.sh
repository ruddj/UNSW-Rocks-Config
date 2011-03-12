#!/bin/bash

#For each directory find most recent file

OLDTIME=14

#if [ $(find /protected/folder -atime -5 | wc -l) -eq 0 ]; then rm -r /protected/folder ; fi

for chkDir in $(find /state/partition2/*.* -type d) 
do
  if [ $(find $chkDir -mtime -$OLDTIME | wc -l) -eq 0 ]
   then 
     echo "Deleting $chkDir from `hostname`"
     rm -r $chkDir 
  fi
done

