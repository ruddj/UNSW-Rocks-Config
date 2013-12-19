# Gaussian RPM Build
# $Id: gaussian09-A.02.spec 52 2010-05-21 06:57:31Z ruddj $
# Build Command (Build root due to low space on /var)
# rpmbuild -bb --target x86_64 --buildroot ~ruddj/redhat/tmp/gaussian09-root/ SPECS/gaussian09-A.02.spec

%define _topdir	 	/home/ruddj/redhat
%define name		gaussian09 
%define release		2
%define version 	A.02

%define buildroot %{_topdir}/tmp/%{name}-%{version}-root

%define installdir    /gaussian/g09a

Summary: gaussian 09 chemical simulation package with Linda
Name: 		%{name}
Version: 	%{version}
Release: 	%{release}
License: Commercial
Group: Applications/Engineering
URL: http://www.gaussian.com/
Source: OPT-920N.tgz
Vendor: University of New South Wales
Packager: James Rudd <james.rudd@gmail.com>
BuildRoot: %{buildroot}

%description
Gaussian simulation and chemical modeling package. With Linda.

Starting from the basic laws of quantum mechanics, Gaussian predicts the energies, molecular structures, and vibrational frequencies of molecular systems, along with numerous molecular properties derived from these basic computation types. It can be used to study molecules and reactions under a wide range of conditions, including both stable species and compounds which are difficult or impossible to observe experimentally such as short-lived intermediates and transition structures. 

%prep
#%setup -n g09
#export PERL=/usr/bin/perl


%build


%install
export g09root=$RPM_BUILD_ROOT%{installdir}
mkdir -p $RPM_BUILD_ROOT%{installdir}
cd $RPM_BUILD_ROOT%{installdir}
#cat /usr/src/redhat/SOURCES/gaussian03-D.01.taz | zcat | tar xvf -
#gunzip -c /mnt/gaussCD/G09Bin/tar/OPT-920N.tgz | tar xvf -
tar xzvf /home/ruddj/install/g09/OPT_920N.TGZ 

#cleanup perl statments
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $g09root/g09/bsd/*
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $g09root/g09/tests/*.pl
sed -i -s 's/use GauUtil/#use GauUtil/' $g09root/g09/bsd/fetch-ref

# allow Linda to use SGE rsh
sed -i 's/exec \/usr\/bin\/rsh /exec rsh /' $g09root/g09/linda8.2/opteron-linux/bin/linda_rsh
# Use fast SSH algorithm
sed -i 's/exec \/usr\/bin\/ssh -x /exec \/usr\/bin\/ssh -x -c arcfour /' $g09root/g09/linda8.2/opteron-linux/bin/linda_rsh

#cleanup paths, hard codes location
find $g09root/g09 -type f | xargs -n 1 chrpath 2>&1 | grep RPATH | sed -e 's/:.*//' > /tmp/chrpath.todo
chrpath -r %{installdir}/g09 `cat /tmp/chrpath.todo`
rm /tmp/chrpath.todo

chown -R root:users g09 
#cd $RPM_BUILD_ROOT/gaussian/g09
#./bsd/install
#cd $RPM_BUILD_ROOT
 

%post
#chgrp -R gaussian $RPM_BUILD_ROOT/gaussian/g09 
cd %{installdir}/g09
echo "-M- 800MB" > Default.Route
echo "-P- 4" >> Default.Route
echo "-#- MaxDisk=20GB" >> Default.Route
echo "-S- PVGauss_"`hostname -s` >> Default.Route

./bsd/install

chown -R root:users %{installdir}/g09

%clean
rm -rf $RPM_BUILD_ROOT


%files
#%defattr(-,root,users) /gaussian/g09/ 
#%dir /gaussian/g09/
%{installdir}/g09
