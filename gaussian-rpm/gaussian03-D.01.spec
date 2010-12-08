Summary: gaussian 03 chemical simulation package with Linda
Name: gaussian03
Version: D.01
Release: 1
Copyright: Commercial
Group: Applications/Engineering
URL: http://www.gaussian.com/
Source: /usr/src/redhat/SOURCES/gaussian03-D.01.taz
Vendor: University of New South Wales
Packager: James Rudd <rudd_j@yahoo.com>
BuildRoot: %{_tmppath}/%{name}-root

%description
Gaussian simulation and chemical modeling package. With Linda.

Starting from the basic laws of quantum mechanics, Gaussian predicts the energies, molecular structures, and vibrational frequencies of molecular systems, along with numerous molecular properties derived from these basic computation types. It can be used to study molecules and reactions under a wide range of conditions, including both stable species and compounds which are difficult or impossible to observe experimentally such as short-lived intermediates and transition structures. 

%prep
#%setup -n g03
#export PERL=/usr/bin/perl


%build


%install
export g03root=$RPM_BUILD_ROOT/gaussian
mkdir -p $RPM_BUILD_ROOT/gaussian
cd $RPM_BUILD_ROOT/gaussian
cat /usr/src/redhat/SOURCES/gaussian03-D.01.taz | zcat | tar xvf -

#cleanup perl statments
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $RPM_BUILD_ROOT/gaussian/g03/bsd/*
sed -i -s 's/\/usr\/local\/bin\/perl/\/usr\/bin\/perl/' $RPM_BUILD_ROOT/gaussian/g03/tests/*.pl
sed -i -s 's/use GauUtil/#use GauUtil/' $RPM_BUILD_ROOT/gaussian/g03/bsd/check-subs

#cleanup paths, hard codes location
find $RPM_BUILD_ROOT/gaussian/g03 -type f | xargs -n 1 chrpath 2>&1 | grep RPATH | sed -e 's/:.*//' > /tmp/chrpath.todo
chrpath -r /gaussian/g03 `cat /tmp/chrpath.todo`
rm /tmp/chrpath.todo

chown -R root:users g03 
#cd $RPM_BUILD_ROOT/gaussian/g03
#./bsd/install
#cd $RPM_BUILD_ROOT
 

%post
#chgrp -R gaussian $RPM_BUILD_ROOT/gaussian/g03 
cd $RPM_BUILD_ROOT/gaussian/g03
echo "-M- 800MB" > Default.Route
echo "-P- 4" >> Default.Route
echo "-#- MaxDisk=20GB" >> Default.Route
echo "-S- PVGauss_"`hostname -s` >> Default.Route

./bsd/install

chown -R root:users $RPM_BUILD_ROOT/gaussian/g03

%clean
rm -rf $RPM_BUILD_ROOT


%files
#%defattr(-,root,users) /gaussian/g03/ 
#%dir /gaussian/g03/
/gaussian/g03/
