#!/bin/bash

rollName=Dell-OMSA
now=$(date +"%Y-%m-%d")
rollTime=$(date +"%T")
rollDate=$(date +"%b %d %Y")

#wget --mirror --continue --progress=dot:mega --no-parent \
#-erobots=off  --cut-dirs=4 \
#--exclude-directories='/repo/hardware/latest/platform_independent/rh60_64/payloads,payloads,/repo/hardware/latest/platform_independent/rh60_64/headers,headers,/repo/hardware/latest/platform_independent/rh60_64/repoview,repoview' \
#--directory-prefix /export/rocks/update/dell \
#http://linux.dell.com/repo/hardware/latest/platform_independent/rh60_64/

rsync -avHz --delete --exclude '*/payloads' --exclude '*/headers' --exclude '*/repoview' \
 linux.dell.com::repo/hardware/latest/platform_independent/rh60_64  linux.dell.com

# Rocks Rolls only imports RPMs with version info
pushd linux.dell.com/rh60_64/firmware-tools
for RPM in $(ls *.rpm |grep -v el6) ; do
  /bin/cp $RPM $(rpm -qp $RPM).rpm
done
popd

pushd linux.dell.com/rh60_64/srvadmin-x86_64
for RPM in $(ls *.rpm |grep -v el6) ; do
  /bin/cp $RPM $(rpm -qp $RPM).rpm
done
popd

cat > roll-$rollName.xml <<_EOF
<roll name="$rollName" interface="4.0">
        <timestamp time="$rollTime" date="$rollDate" tz="EST"/>
        <color edge="lawngreen" node="lawngreen"/>
        <info version="$now" release="0" arch="x86_64"/>
        <iso maxsize="0" bootable="0" mkisofs=""/>
        <rpm rolls="0" bin="1" src="0"/>
</roll>
_EOF

ln -s linux.dell.com RPMS

rocks create roll roll-$rollName.xml

rm -rf disk1
rm RPMS

rocks disable roll $rollName
rocks remove roll $rollName

rocks add roll $rollName-$now-0.x86_64.disk1.iso
rocks enable roll $rollName
cd /export/rocks/install
rocks create distro

