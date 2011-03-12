#!/bin/bash
# Based on http://goc.pragma-grid.net/wiki/index.php/Tools_box
# Use this script as the termination method for SGE queues rather than the 
# default which just does SIGKILL and therefore does not give jobs that have 
# forked worker children the chance to kill them.
# The termination_method of the queue config can pass in other arguments to 
# variations of this script such as $job_owner $queue $host

if [ $# -ne 2 ] ; then
  echo "Usage:" $0 job_pid job_owner
  exit 1
fi

job_pid=$1
job_owner=$2

# First send sigint ctrl+c
pkill -SIGINT -s $job_pid if [ $? -ne 0 ] ; then
        kill -SIGINT $job_pid
fi

# cleanup grace period
sleep 30

# try and kill the session group - the group leader is the shell 
# executing the job script 
pkill -TERM -s $job_pid if [ $? -ne 0 ] ; then
        kill -TERM $job_pid
fi

# cleanup grace period
sleep 30
pkill -KILL -s $job_pid
if [ $? -ne 0 ] ; then
        kill -KILL $job_pid
fi

# check for detached children that weren't killed by session 
# sanity check first...
#if [ $job_owner = "root" ] ; then
#       exit
#else
# look for processes belonging to the user with PPID 1
#       pgrep -u $job_owner -P 1
#       det=$?
#       while [ $det -eq 0 ] ; do
#               pkill -9 -u $job_owner -P 1
#               sleep 2
#               pgrep -u $job_owner -P 1
#               det=$?
#       done
#fi

