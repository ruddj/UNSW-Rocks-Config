#!/bin/bash

rollName=dell-OMSA
now=$(date +"%Y-%m-%d")
rollVer=$(date +"%Y%m%d")
rollTime=$(date +"%T")
rollDate=$(date +"%b %d %Y")
rollBuild=$(pwd)
rollMirror=$rollBuild/linux.dell.com

#wget --mirror --continue --progress=dot:mega --no-parent \
#-erobots=off  --cut-dirs=4 \
#--exclude-directories='/repo/hardware/latest/platform_independent/rh60_64/payloads,payloads,/repo/hardware/latest/platform_independent/rh60_64/headers,headers,/repo/hardware/latest/platform_independent/rh60_64/repoview,repoview' \
#--directory-prefix /export/rocks/update/dell \
#http://linux.dell.com/repo/hardware/latest/platform_independent/rh60_64/

rsync -avHz --delete --exclude '*/payloads' --exclude '*/headers' --exclude '*/repoview' \
 linux.dell.com::repo/hardware/latest/platform_independent/rh60_64  $rollMirror

# Rocks Rolls only imports RPMs with version info
pushd $rollMirror/rh60_64/firmware-tools
for RPM in $(ls *.rpm |grep -v el6) ; do
  /bin/cp $RPM $(rpm -qp $RPM).rpm
done
popd

pushd $rollMirror/rh60_64/srvadmin-x86_64
for RPM in $(ls *.rpm |grep -v el6) ; do
  /bin/cp $RPM $(rpm -qp $RPM).rpm
done
popd


# Auto Create
if false ; then
cat > roll-$rollName.xml <<_EOF
<roll name="$rollName" interface="4.0">
        <timestamp time="$rollTime" date="$rollDate" tz="EST"/>
        <color edge="lawngreen" node="lawngreen"/>
        <info version="$rollVer" release="0" arch="x86_64"/>
        <iso maxsize="0" bootable="0" mkisofs=""/>
        <rpm rolls="0" bin="1" src="0"/>
</roll>
_EOF

ln -s linux.dell.com RPMS
rocks create roll roll-$rollName.xml

rm -rf disk1
rm RPMS
fi

# Custom Create
# rocks create new roll
rm -rf $rollName/
rocks create new roll $rollName version=$rollVer color=brown
pushd $rollBuild/$rollName
rm -rf src/
mkdir RPMS/

# hard link in RPMs
ln $rollMirror/rh60_64/*/*.rpm RPMS/

# Modify Nodes and graph files

cat > $rollBuild/$rollName/graphs/default/$rollName.xml <<_EOF
<?xml version="1.0" standalone="no"?>
<graph roll="$rollName" >
        <description>
        Dell OpenManage Server Administrator packages to admin DRACs on nodes
        </description>

        <copyright>
        Roll created by James Rudd using packages from Dell.
        </copyright>

        <changelog>
        \$Log\$
        </changelog>

	<edge from="client">
		<to>$rollName</to>
	</edge>

	<edge from="server">
		<to>$rollName</to>
	</edge>
</graph>
_EOF

cat > $rollBuild/$rollName/nodes/$rollName.xml <<_EOF
<?xml version="1.0" standalone="no"?>
<kickstart>
        <description>
        Dell OpenManage Server Administrator packages to admin DRACs on nodes
        </description>

        <copyright>
        Roll created by James Rudd using packages from Dell.
        </copyright>

        <changelog>
        \$Log\$
        </changelog>

        <package>libsmbios</package>
        <package>smbios-utils</package>
        <package>yum-dellsysid</package>
        <package>srvadmin-idrac</package>
        <package>srvadmin-idrac7</package>
</kickstart>
_EOF

make roll

rocks disable roll $rollName
rocks remove roll $rollName

rocks add roll $rollName-$rollVer-0.x86_64.disk1.iso
rocks enable roll $rollName
popd
#cd /export/rocks/install
#rocks create distro


