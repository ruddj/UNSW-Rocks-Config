#! /bin/bash
#
# BASH script to configure IPoIB for non front end nodes in a Rocks 6.1 cluster.
# IP address scheme for InfiniBand (ib0) will reflect that of Ethernet (eth0).
# Must be root to run this script.
 
# Function to convert the first character in a string to uppercase
function ucfirst_character () {
  original_string="$@"               
  first_character=${original_string:0:1}   
  rest_of_the_string=${original_string:1}       
  first_character_uc=`echo "$first_character" | tr a-z A-Z`
  echo "${first_character_uc}${rest_of_the_string}"  
}
 
 
# Necessary variables 
# Remove login and/or nas from the list below if the cluster does not have login and/or NAS nodes
#export MYNODETYPES="login nas compute"
export MYNODETYPES="compute-2"
 
# Outer for loop begins
for x in $MYNODETYPES
do
 
  # List of nodes of given type (login, nas or compute)
  export MYNODES=`rocks list host | grep "$x" | awk -F ':' '{ print $1 }' | sort -t- -k 2,2n -k 3,3n`
 
  # /etc/hosts.local header for a given type of node
  if [ $x == "nas" ]
  then
    export y=`echo $x | tr a-z A-Z`
  else
    export y=`ucfirst_character $x`
  fi
  echo "# $y node(s)" >> /etc/hosts.local
 
  # Inner for loop begins
  for MYHOSTNAME_ETH0 in $MYNODES
  do
    #
    # Additiional necessary variables
    export MYHOSTNAME_IB0="ib-$MYHOSTNAME_ETH0"
    export MYHOSTIP_ETH0=`rocks list host interface $MYHOSTNAME_ETH0 | grep "em1" | awk '{ print $4 }'`
    export MYHOSTIP_IB0=`echo $MYHOSTIP_ETH0 | sed 's/10.1/10.2/g'`
    export MYSHORTNAME_ETH0=`echo $MYHOSTNAME_ETH0 | sed 's/compute/c/g' | sed 's/login/l/g' | sed 's/nas/n/g'`
    export MYSHORTNAME_IB0=`echo $MYHOSTNAME_IB0   | sed 's/compute/c/g' | sed 's/login/l/g' | sed 's/nas/n/g'`
 
    #
    # Network
    rocks set host interface ip $MYHOSTNAME_ETH0 iface=ib0 ip=$MYHOSTIP_IB0
    rocks set host interface subnet $MYHOSTNAME_ETH0 iface=ib0 subnet=ibnet
    rocks set host interface module $MYHOSTNAME_ETH0 iface=ib0 module=ip_ipoib
    rocks set host interface name $MYHOSTNAME_ETH0 iface=ib0 name=$MYHOSTNAME_ETH0
    rocks sync host network $MYHOSTNAME_ETH0
 
    #
    # Firewall
    rocks add firewall host=$MYHOSTNAME_ETH0 chain=INPUT protocol=all service=all action=ACCEPT network=ibnet iface=ib0 rulename="A80-IB0-PRIVATE"
    rocks sync host firewall $MYHOSTNAME_ETH0
 
    #
    # For debugging purposes only
    printf "%-14s  %-20s  %-14s  %-18s  %-10s\n"  "${MYHOSTIP_ETH0}" "${MYHOSTNAME_ETH0}.local" "${MYSHORTNAME_ETH0}.local" "${MYHOSTNAME_ETH0}" "${MYSHORTNAME_ETH0}"
    printf "%-14s  %-20s  %-14s  %-18s  %-10s\n"  "${MYHOSTIP_IB0}"  "${MYHOSTNAME_ETH0}.ibnet" "${MYSHORTNAME_ETH0}.ibnet" "${MYHOSTNAME_IB0}"  "${MYSHORTNAME_IB0}"
 
    #
    # /etc/hosts.local
    printf "%-14s  %-20s  %-14s  %-18s  %-10s\n"  "${MYHOSTIP_ETH0}" "${MYHOSTNAME_ETH0}.local" "${MYSHORTNAME_ETH0}.local" "${MYHOSTNAME_ETH0}" "${MYSHORTNAME_ETH0}" >> /etc/hosts.local
    printf "%-14s  %-20s  %-14s  %-18s  %-10s\n"  "${MYHOSTIP_IB0}"  "${MYHOSTNAME_ETH0}.ibnet" "${MYSHORTNAME_ETH0}.ibnet" "${MYHOSTNAME_IB0}"  "${MYSHORTNAME_IB0}"  >> /etc/hosts.local
 
  done
  # Inner for loop ends
 
done
# Outer for loop ends
