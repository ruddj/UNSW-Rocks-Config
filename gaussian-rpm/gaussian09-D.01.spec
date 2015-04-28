# Gaussian RPM Build
# $Id: gaussian09-A.02.spec 52 2010-05-21 06:57:31Z ruddj $
# Build Command (Build root due to low space on /var)
# rpmbuild -bb --target x86_64 --buildroot ~ruddj/redhat/tmp/gaussian09-root/ SPECS/gaussian09-D.01.spec

%define _topdir	 	/home/ruddj/redhat
%define name		gaussian09 
%define release		1
%define version 	D.01

%define buildroot %{_topdir}/tmp/%{name}-%{version}-root
%define __find_requires 	%{_tmppath}/%{name}-requires.sh
%define _use_internal_dependency_generator 0

Summary: gaussian 09 chemical simulation package with Linda
Name: 		%{name}
Version: 	%{version}
Release: 	%{release}
License: Commercial
Group: Applications/Engineering
URL: http://www.gaussian.com/
Source: E64-590N.tgz
Vendor: University of New South Wales
Packager: James Rudd <james.rudd@gmail.com>
BuildRoot: %{buildroot}
#AutoReq: no
#AutoReqProv: no
BuildRequires: chrpath


%description
Gaussian simulation and chemical modeling package. With Linda.

Starting from the basic laws of quantum mechanics, Gaussian predicts the energies, molecular structures, and vibrational frequencies of molecular systems, along with numerous molecular properties derived from these basic computation types. It can be used to study molecules and reactions under a wide range of conditions, including both stable species and compounds which are difficult or impossible to observe experimentally such as short-lived intermediates and transition structures. 

%prep
#%setup -n g09
#export PERL=/usr/bin/perl


%build


%install
export g09root=$RPM_BUILD_ROOT/gaussian
mkdir -p $RPM_BUILD_ROOT/gaussian
cd $RPM_BUILD_ROOT/gaussian
#cat /usr/src/redhat/SOURCES/gaussian03-D.01.taz | zcat | tar xvf -
#gunzip -c /mnt/gaussCD/G09Bin/tar/OPT-920N.tgz | tar xvf -
tar xzvf /home/ruddj/install/gaussian/E64-590N.tgz

#cleanup perl statments
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $RPM_BUILD_ROOT/gaussian/g09/bsd/*
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $RPM_BUILD_ROOT/gaussian/g09/tests/*.pl
sed -i -s 's/use GauUtil/#use GauUtil/' $RPM_BUILD_ROOT/gaussian/g09/bsd/fetch-ref

# allow Linda to use SGE rsh
sed -i 's/exec \/usr\/bin\/rsh /exec rsh /' $RPM_BUILD_ROOT/gaussian/g09/linda8.2/opteron-linux/bin/linda_rsh
# Use fast SSH algorithm
sed -i 's/exec \/usr\/bin\/ssh -x /exec \/usr\/bin\/ssh -x -c arcfour /' $RPM_BUILD_ROOT/gaussian/g09/linda8.2/opteron-linux/bin/linda_rsh

#cleanup paths, hard codes location
find $RPM_BUILD_ROOT/gaussian/g09 -type f | xargs -n 1 chrpath 2>&1 | grep RPATH | sed -e 's/:.*//' > /tmp/chrpath.todo
chrpath -r /gaussian/g09 `cat /tmp/chrpath.todo`
rm /tmp/chrpath.todo

chown -R root:users g09 
#cd $RPM_BUILD_ROOT/gaussian/g09
#./bsd/install
#cd $RPM_BUILD_ROOT

# Run the requirement generator, but strip out the requirements we are ignoring.
# This is the script referenced in the __find_requires macro above.
echo "#!/bin/sh" > %{_tmppath}/%{name}-requires.sh
echo '/usr/lib/rpm/rpmdeps --requires | egrep -v "^(perl\()"' >> %{_tmppath}/%{name}-requires.sh
#echo '/usr/lib/rpm/rpmdeps --requires | egrep -v "^(perl\(Data::Dumper\))$"' >> %{_tmppath}/%{name}-requires.sh
chmod 0700 %{_tmppath}/%{name}-requires.sh
 

%post
#chgrp -R gaussian $RPM_BUILD_ROOT/gaussian/g09 
cd $RPM_BUILD_ROOT/gaussian/g09
echo "-S- PVGauss_"`hostname -s` > Default.Route
#echo "-M- 800MB" >> Default.Route
#echo "-P- 4" >> Default.Route
#echo "-#- MaxDisk=20GB" >> Default.Route

./bsd/install

chown -R root:users $RPM_BUILD_ROOT/gaussian/g09

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{_tmppath}/%{name}-requires.sh

%files
#%defattr(-,root,users) /gaussian/g09/ 
#%dir /gaussian/g09/
/gaussian/g09/
