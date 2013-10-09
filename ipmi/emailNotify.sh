#!/bin/bash
passfile=~ruddj/ipmipass
dellPass=`cat $passfile`


for i in {0..0}
do
 echo "Compute-1-$i"
 /opt/dell/srvadmin/sbin/racadm -r ipmi-1-$i.ipmi -u root -p $dellPass config -g cfgIpmiLan -o cfgIpmiLanAlertEnable 1
 /opt/dell/srvadmin/sbin/racadm -r ipmi-1-$i.ipmi -u root -p $dellPass config -g cfgEmailAlert -o cfgEmailAlertEnable -i 1 1
 /opt/dell/srvadmin/sbin/racadm -r ipmi-1-$i.ipmi -u root -p $dellPass config -g cfgEmailAlert -o cfgEmailAlertAddress -i 1 root@GaussHPC.ad.unsw.edu.au
 /opt/dell/srvadmin/sbin/racadm -r ipmi-1-$i.ipmi -u root -p $dellPass config -g cfgRemoteHosts -o cfgRhostsSmtpServerIpAddr 10.1.1.1
done

for i in {0..6}
do
 echo "Compute-2-$i"
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgIpmiLan -o cfgIpmiLanAlertEnable 1
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgEmailAlert -o cfgEmailAlertEnable -i 1 1
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgEmailAlert -o cfgEmailAlertAddress -i 1 root@GaussHPC.ad.unsw.edu.au
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgRemoteHosts -o cfgRhostsSmtpServerIpAddr 10.1.1.1
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgLanNetworking -o cfgDNSDomainName ad.unsw.edu.au
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgLanNetworking -o cfgDNSRacName  Gauss-C2-$i
 /opt/dell/srvadmin/sbin/racadm -r ipmi-2-$i.ipmi -u root -p $dellPass config -g cfgLanNetworking -o cfgDNSServer1 10.1.1.1
done

