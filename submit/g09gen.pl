#!/usr/bin/perl -w
########################################
# Perl script for generating SGE submission scripts
#
# Generates SGE settings and sets defaults in 
# gaussian file
#
# Written by James Rudd, james.rudd@gmail.com
# 20061216
# Tracking now done by GIT
########################################
use strict; use warnings;
use File::Basename;

die "Usage: g09gen GaussFileName [NumNodes]" unless (@ARGV >= 1);
print "SGE submission script generation\n";

sub CheckSettings($); 

MAIN:

#set defaults or load in file
my $G03ROOT="/gaussian";
my $gScratch="/state/workspace"; # or "\$TMPDIR"
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.G03SGE";
my $gaussFile=$ARGV[0];
my $numNodes = 0;
$numNodes=$ARGV[1] if (@ARGV >= 2);

my $MEM="400MB";
my $MEMOD=0; #overide value
my $PROCSHARED=4; # how many processors for each PC
my $PROCSHAREDOD=1; #overide value

my $EMAILNOTIFY="beas";
my $EMAIL="dirk.koenig\@unsw.edu.au";


# Data Checks
die "Could not read $gaussFile\n" if (! -f $gaussFile);
die "$numNodes is not a number\n" if ($numNodes =~ /\D/);
$numNodes = 0 if ($numNodes <2); #Need at least 2 to use linda

#get basename
my ($file,$dir,$ext) = fileparse($gaussFile, qr/\.[^.]*/);

#read in defaults
if ( -f $CONFIGFILE){
	print "\tLoading config file $CONFIGFILE\n";
	open CONFIG, " < $CONFIGFILE" or last;
	foreach my $line (<CONFIG>){
		chomp $line;
		next if ($line =~ /^#/);
		
		if ($line =~ /^MEMOD[\s]*=[\s]*([\d]+)/i){
			$MEMOD=$1;
		}
		elsif ($line =~ /^PROCSHAREDOD[\s]*=[\s]*([\d]+)/i){
			$PROCSHAREDOD=$1;
		}
		elsif ($line =~ /^PROCSHARED[\s]*=[\s]*([\d]+)/i){
			$PROCSHARED=$1;
		}
		elsif ($line =~ /^EMAILNOTIFY[\s]*=[\s]*([\w]+)/i){ 
			if ($line =~ /^EMAILNOTIFY[\s]*=[\s]*([beasn]+)[\s]*(#|$)/i){ 
				$EMAILNOTIFY=$1;
			}
			else {
				print "Warning: Config contains invalid email notify codes\n";
			}
		}
		elsif ($line =~ /^EMAIL[\s]*=[\s]*([^\s]+)/i){ 
			$EMAIL=$1;
		}
		elsif ($line =~ /^MEM[\s]*=[\s]*([\d]+[\w]*)/i){ 
			$MEM=$1;
		}
		
	}
	close CONFIG;
}
else {
	print "\tNo config file. Using defaults and creating default config: $CONFIGFILE\n";
	open CONFIG, " > $CONFIGFILE";
	print CONFIG <<CONF;
#Following sets SGE Options
#EMAILNOTIFY=beas 	# Notify actions for email
#EMAIL=me\@unsw.edu.au	# Email address to send to

#Following sets options inside Gaussian file
#MEM=440MB 		# Set the memory / CPU
#MEMOD=0 		# Overide the memory value
PROCSHARED=4		# Use this many shared processors in Gaussian File
PROCSHAREDOD=1		# Overide the number of shared CPU value

CONF
	close CONFIG;
}

my $numCores = $numNodes * $PROCSHARED;

#create default script
open SCRIPT, "> submit$file.sh" or die "Could not create file";

print "\tCreating SGE file: submit$file.sh\n";

my $queueAllo;
if ($numNodes) {
	print "\t\twith $numNodes nodes and $numCores cores.\n";
	$queueAllo = "\# Use Parallel Queue (sequence: dell.pe,dell.pe2,compute.q,dell.q,dell.qm)\n\# You must include masterq queue in this list\n";
	$queueAllo .= "\#\$ -q dell.pe,dell.pe2,compute.q,dell.qm\n";
	$queueAllo .= "\# The master process must run on a node in this queue(either dell.q or dell.qm)\n# Use dell.q if you do not have rights to dell.qm\n";
	$queueAllo .= "\#\$ -masterq dell.qm\n";
	$queueAllo .= "\# \n\# Setting gauss=0 allows slave calculations to run on nodes already doing calculations.\n#  \$ -l gauss=0";
} 
else {
	print "\t\twith 1 node\n";
	$queueAllo = "\# Use the Standard Queues (can be compute.q,dell.q)\n\#\$ -q compute.q,dell.q";
} 

# SGE Options
print SCRIPT <<SGESET;
\#!/bin/bash

\# Grid Engine Settings 
\# Grid engine reads in any line beginning with \#\$ as a qsub argument.
\# Specify job name.
\#\$ -N "$file" 
\# Command interpreter to be used.
\#\$ -S /bin/bash
\# Use current working directory.
\#\$ -cwd
\# Merge stdout and stderr stream of job (y/n).
\#\$ -j y
\# Have SGE Notify job it is about to be terminated
\#\$ -notify
\# Define the job\'s relative priority (-1023 to 1024); Std 0.
\#\$ -p 0
\# Following are soft settings
\#\$ -soft
$queueAllo
\# Remainder are hard settings
\#\$ -hard
\# Remove spaces between #\$ to force excution on a specific node
\#  \$ -l hostname="compute-0-?"
SGESET


if ($EMAIL){
print SCRIPT "\# Notify these e-mail addresses.\n",
	"\#\$ -M $EMAIL\n",
	"\# Define mail notification events.\n",
	"\# [e]nd, [b]eginning, [a]bort, [n]ever mail, [s]uspension\n",
	"\#\$ -m $EMAILNOTIFY\n",
}

if ($numNodes){
	print SCRIPT "\# Request processors for parallel jobs.(nodes * proc/node)\n",
	"\#\$ -pe g03 " . $numNodes * $PROCSHARED ."\n";
} 
else {
	print SCRIPT "\# Set SMP slots for local job.\n",
	"\#\$ -pe smp $PROCSHARED\n";

}

# Gauss Options

print SCRIPT  <<GAOPT;

echo "Working directory is:"
pwd
\# Gaussian Environment settings
\#export g09root=\"$G03ROOT\"
\# source \$g09root/g09/bsd/g09.profile
source /etc/profile
\# Loads Gaussian application directory
module load g09

export GAUSS_SCRDIR=\"$gScratch/\$USER.\$JOB_ID\"
export GAUSS_USER=`pwd`
export g09error=""
GAOPT

my $g09exe="g09";

my $gaussLog=$gaussFile;
#$gaussLog =~ s/\.com$/.log/;
$gaussLog =~ s/\.com$//;
print SCRIPT "export GAUSS_LOG=\"$gaussLog-\${JOB_ID}.log\" \n";


#Echo controlling PC
print SCRIPT "\necho -n \"Master Process is on: \"\n", "hostname\n";
print SCRIPT "\necho -n \"Machine details are: \"\n", "uname -a\n";
print SCRIPT "echo \"Local Working Directory: \$GAUSS_SCRDIR\"\n";
print SCRIPT "echo \"Server Directory: \$GAUSS_USER\"\n";
print SCRIPT "echo \"Log File is: \$GAUSS_LOG\"\n";

# Linda Options	
# May need to add commands to create scratch directories on nodes using SSH
# may also need to sort node list so Master started on highmem pcs
if ($numNodes){
	my $lindaNodes=$numNodes-1;
	print SCRIPT <<LINDA;
	
\# Read in Node List 
export NODES=\`awk \'{print \$1 }\' \$PE_HOSTFILE\`

\# Linda Environment settings
export GAUSS_LFLAGS=\"-v -nodelist \'\${NODES}\' -n $lindaNodes\"
export GAUSS_EXEDIR=\"\$g09root/g09/linda-exe:\$GAUSS_EXEDIR\"

echo "Got \$NSLOTS processors."
echo "Machines: \$NODES"

\# Create scratch directories on nodes using SSH
for node in \`cat \$PE_HOSTFILE | cut -d\' \' -f1|sort -r\`; do
  echo "Creating scratch directory on \$node"
  ssh \$node "mkdir \$GAUSS_SCRDIR ; chgrp users \$GAUSS_SCRDIR ; chmod 2775 \$GAUSS_SCRDIR"
done

LINDA

} 

# Setup Scratch Disk
print SCRIPT  <<SCRATCHOPT;

\# Setup ulimit
\#ulimit -s unlimited
\# also ulimit -S 32768
\# ulimit -s 128000
#ulimit -s 32768

\# Clean and Setup Scratch Disk
if [ -d \$GAUSS_SCRDIR ]; then
   rm -rf \$GAUSS_SCRDIR
fi

mkdir \$GAUSS_SCRDIR
chgrp users \$GAUSS_SCRDIR
chmod 2775 \$GAUSS_SCRDIR

SCRATCHOPT

print SCRIPT "\# Main Program Run\n";

print SCRIPT "date\n", 
	"cd \$GAUSS_SCRDIR\n",  
	"time $g09exe <\$GAUSS_USER/$gaussFile &> \$GAUSS_USER/\$GAUSS_LOG  \n", 
	"date\n";
	
#  Scratch cleanup
print SCRIPT  <<SCRATCHOPT;

\# Copy and Remove Scratch Disk
cd \$GAUSS_USER
cp \$GAUSS_SCRDIR/*.chk \$GAUSS_USER
if [ \$? ]; then
  rm -Rf \$GAUSS_SCRDIR
else 
  export g09error="Could not copy files from \$GAUSS_SCRDIR to \$GAUSS_USER"
  echo \$g09error
fi

SCRATCHOPT

if ($numNodes){
print SCRIPT <<LINDA;

\# Remove scratch directories on nodes using SSH
for node in \`cat \$PE_HOSTFILE | cut -d\' \' -f1|sort -r\`; do
  ssh \$node "rm -Rf \$GAUSS_SCRDIR"
done

LINDA

}

# Manual Email
# Am not receiving emails sent through nodes using following

print SCRIPT "\n\# Email finish report\n",
	'perl -e "print \"Your job $JOB_ID in queue $QUEUE is done\n', 
	"$gaussFile in folder \$GAUSS_USER completed at `date`\\n\$g09error\\n\\\",",
	"\\\`tail -10 \$GAUSS_LOG\\\`, \\\"\\n",
	"\\\";\" \\\n| /bin/mail -s \"Job \$JOB_ID Completed\" $EMAIL",
	"\n\n";
	
print SCRIPT 'echo "Finished job $JOB_ID"';
close SCRIPT;
# Modify gaussian .com file
# load in file
open GAUSSCOM, " < $gaussFile";
my @GaussIn = <GAUSSCOM>;
close GAUSSCOM;


print "\tUpdating Gaussian file: $gaussFile\n";
open GAUSSCOM, " > $gaussFile";

my $lineNum = CheckSettings(0);

for (; $lineNum < @GaussIn; $lineNum++){
	my $line = $GaussIn[$lineNum];
	# strip comments and junk
	chomp $line;
	if ($line =~ /--Link1--/){
		$lineNum = CheckSettings($lineNum) -1;
		next;
	}
	print GAUSSCOM $line, "\n";
}

close GAUSSCOM;

print "Completed SGE preperation\n";


exit(0);


################
# Reads in settings for each link and sets defaults
################
sub CheckSettings($){

	# need to read in settings and output if needed
	my $count = $_[0];
	my @settings;
	my ($nProc,$nLinda,$nMem)=(0,0,0);
	SETTINGS: for (;$count < @GaussIn; $count++){
		my $line = $GaussIn[$count];
		chomp $line;
		if ($line =~ /^\#/){
			# Last line begins with a #
			#print "Start Gauss\n";	
			last SETTINGS;
		}
		elsif ($line =~ /^\%nprocl[\w]*\s*=\s*([\d]+)/i){
	 		# $nLinda = $1; # set by script
		}
		elsif ($line =~ /^\%NProc[\w]*[\s]*=[\s]*([\d]+)/i){	
			$nProc = $1;	
		}
		elsif ($line =~ /^\%mem\s*=\s*([\d]+[\w]*)/i){
			$nMem = $1;
		}
		else {
			print GAUSSCOM $line, "\n";
		}
	}

	#check nproc
	if ($PROCSHAREDOD or $nProc == 0){
		print GAUSSCOM "\%NProcShared=$PROCSHARED\n";
	}
	else {
		print GAUSSCOM "\%NProcShared=$nProc\n";
	}

	# check nprocl
	if ($nLinda){
		print GAUSSCOM "\%NProcLinda=$nLinda\n";
	}
	elsif ($numNodes){
		print GAUSSCOM "\%NProcLinda=$numNodes\n";
	}

	# check mem
	if ($MEMOD or ($nMem eq 0)){
		print GAUSSCOM "\%Mem=$MEM\n";		
	}
	else {
		print GAUSSCOM "\%Mem=$nMem\n";
	}

	return $count;
}

