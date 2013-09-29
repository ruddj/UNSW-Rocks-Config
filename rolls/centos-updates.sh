#!/bin/bash

now=$(date +"%Y-%m-%d")
rocks create mirror http://mirror.aarnet.edu.au/pub/centos/6/updates/x86_64/Packages/ rollname=Updates-CentOS  version=$now

rocks disable roll Updates-CentOS
rocks remove roll Updates-CentOS

rocks add roll Updates-CentOS-$now-0.x86_64.disk1.iso
rocks enable roll Updates-CentOS
cd /export/rocks/install
rocks create distro 
