#!/usr/bin/perl -w
########################################
# Perl script for restarting nodes
#
#
# Written by James Rudd, james.rudd@gmail.com
# 20061216
# Updated 
# $LastChangedDate: 2007-07-06 16:02:12 +1000 (Fri, 06 Jul 2007) $
# $Id: g03gen.pl 20 2007-07-06 06:02:12Z ruddj $
#
#
#for i in {0..13} 
#do
# echo "Dell-0-$i"
# ./reinstall.pl d0-$i  
#done


########################################
use strict; use warnings;

my $nodeName=$ARGV[0];

if ($nodeName =~ /^[cd]\d+-\d+$/) {
	print "Short Name\n";
	if ($nodeName =~ /^c/){
		$nodeName =~ s/^c/compute-/;
	}
	elsif ($nodeName =~ /^d/){
		$nodeName =~ s/^d/dell-/;
	}
} 
elsif ($nodeName =~ /^.*-\d+-\d+$/) {
	print "Long Name\n";
} 
else {
	print "Bad Name\n";
	exit 1;
}

print "Will now reinstall $nodeName \n" ;


my @rocks = ("rocks", "set", "host", "boot", $nodeName ,"action=install");
my @reboot = ("ssh", $nodeName , "shutdown", "-r now");
system (@rocks);
    if ($? == -1) {
	print "failed to execute: $!\n";
    }
    elsif ($? & 127) {
	printf "child died with signal %d, %s coredump\n",
	    ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
	printf "child exited with value %d\n", $? >> 8;
    }
    
system (@reboot);
    if ($? == -1) {
	print "failed to execute: $!\n";
    }
    elsif ($? & 127) {
	printf "child died with signal %d, %s coredump\n",
	    ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
	printf "child exited with value %d\n", $? >> 8;
    }

#rocks set host boot dell-0-0 action=install
#ssh dell-0-0 "shutdown -r now"

