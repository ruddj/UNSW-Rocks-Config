#!/usr/bin/perl -w
########################################
# Perl script for generating PBS submission scripts
#
# Generates PBS settings and sets defaults in 
# gaussian file
#
# Written by James Rudd, james.rudd@gmail.com
# 20061216
# Tracking now done by GIT
########################################
use strict; use warnings;
use File::Basename;

die "Usage: g09gen GaussFileName [NumNodes]" unless (@ARGV >= 1);
print "PBS submission script generation\n";

sub CheckSettings($); 

MAIN:

#set defaults or load in file
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.G03SGE";
my $TSNET="$home/.tsnet.config";
my $gaussFile=$ARGV[0];
my $numNodes = 1;
$numNodes=$ARGV[1] if (@ARGV >= 2);

my $MEM="400MB";
my $MEMOD=0; #overide value
my $PROCSHARED=48; # how many processors for each PC
my $PROCSHAREDOD=1; #overide value

my $EMAILNOTIFY="abe";
my $EMAIL="dirk.koenig\@unsw.edu.au";

# Queues

my $queueSelect = 1;

my %queues = (
	'1' =>  {
	    'name' => 'SC1435',
	    'queue' => 'core4-2216',
	    'cpu' => 4,
	    'par' => 1,
	    'pqueue' => 'core4-2216',
	    'maxmem' => 'mem=7gb,vmem=20gb',
	    'module' => 'g09/gbin-A.02',
	    'desc' => 'Jobs on 4 core Dell SC1435'
	    },
	'2'   =>  {
	    'name' => 'R815',
	    'queue' => 'core64-6272',
	    'cpu' => 64,
	    'par' => 1,
	    'pqueue' => 'core64-6272',
	    'maxmem' => 'mem=125gb,vmem=126gb',
	    'module' => 'g09/gbin',
	    'desc' => 'Jobs on 64 core Dell R815'
	    }
);


# Data Checks
die "Could not read $gaussFile\n" if (! -f $gaussFile);
die "$numNodes is not a number\n" if ($numNodes =~ /\D/);
$numNodes = 1 if ($numNodes <2); #Need at least 2 to use linda

#get basename
my ($file,$dir,$ext) = fileparse($gaussFile, qr/\.[^.]*/);

# Check Linda config exists. Needed to use SSH protcol
if (! -f $TSNET){
	print "\tCreating Linda config file $TSNET\n";
	open CONFIG, " > $TSNET";
	print CONFIG <<CONF;
Tsnet.Appl.suffix: False
Tsnet.Appl.verbose: True
Tsnet.Appl.veryverbose: False

Tsnet.Node.lindarsharg: ssh

CONF
	close CONFIG;
}

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
#Following sets PBS Options
#EMAILNOTIFY=abe 	# Notify actions for email
#EMAIL=me\@unsw.edu.au	# Email address to send to

#Following sets options inside Gaussian file
#MEM=20gb 		# Set the memory / CPU
#MEMOD=0 		# Overide the memory value
PROCSHARED=48		# Use this many shared processors in Gaussian File
PROCSHAREDOD=1		# Overide the number of shared CPU value

CONF
	close CONFIG;
}

# Print list of Queues

print "These nodes are avalible:\n";

foreach my $queue ( sort keys %queues )  {
    print "$queue.\t" . $queues{$queue}{'name'} . "\t" . $queues{$queue}{'desc'} . "\n" ;
}

# Ask user which Queue
print "Please type a number corresponding to the nodes you would like to use:\n";
my $answer;
chomp($answer=<STDIN>);

if (exists $queues{$answer}) {
	$queueSelect = $answer;
}
else {
	die "Could not find chosen queue. Exiting.\n";
}

# If Parallel then ask how many nodes 
if ($queues{$queueSelect}{'par'} ) {
	print "How many nodes would you like the job to run on?\n";
	chomp($answer=<STDIN>);
	if ($answer =~ /\D/) {
		die "$answer is not a number.";
	}
	$numNodes = $answer;
	$numNodes = 1 if ($numNodes <2); #Need at least 2 to use linda
}
else {

}

$PROCSHARED = $queues{$queueSelect}{'cpu'};


my $numCores = $numNodes * $PROCSHARED;

#create default script
my $submitFile = "pbs-$file.sh";
open SCRIPT, " > $submitFile" or die "Could not create file";

print "\tCreating PBS file: $submitFile\n";

my $queueAllo;
if ($numNodes > 1) {
        print "\t\twith $numNodes nodes, $PROCSHARED cores/node, Total $numCores cores.\n";
}

# PBS Options
print SCRIPT <<PBSSET;
\#!/bin/bash

\# PBS Settings
\# Torque reads in any line beginning with \#PBS as a qsub argument.
\# Specify job name.
\#PBS -N "$file" 
\# Command interpreter to be used.
\#PBS -S /bin/bash
\# Use current shell Variables.
\# PBS -V
\# Merge stdout and stderr stream of job (y/n).
\#PBS -j oe

\# Set queue
#PBS -q $queues{$queueSelect}{'queue'}

\# Memory Requirments (Max mem=80gb,vmem=40gb)
\# This sets a hard memory limit within the shell. 
\# If not set defaults to 1GB
\# Increase if g09 returns galloc errors 
\#PBS -l $queues{$queueSelect}{'maxmem'}
\# Number of Nodes, Processor per node
\#PBS -l nodes=$numNodes:ppn=$PROCSHARED
\# How long will it run [[HH:]MM:]SS 
\# PBS -l walltime=8:00:00

PBSSET


if ($EMAIL){
print SCRIPT "\# Notify these e-mail addresses.\n",
	"\#PBS -M $EMAIL\n",
	"\# Define mail notification events.\n",
	"\# [e]nd, [b]eginning, [a]bort\n",
	"\#PBS -m $EMAILNOTIFY\n",
}

# Gauss Options

print SCRIPT  <<GAOPT;
cd \$PBS_O_WORKDIR

echo "Working directory is:"
pwd
source /etc/profile

\# Loads Gaussian application directory
module load $queues{$queueSelect}{'module'}

export GAUSS_SCRDIR=\$TMPDIR
export GAUSS_JOBID=\`echo \$PBS_JOBID | cut -d. -f1\`
\#export GAUSS_SCRDIR=\"\$GAUSS_SCRDIR/\$GAUSS_JOBID\"
export GAUSS_USER=\$PBS_O_WORKDIR
export TSNET_PATH=\$GAUSS_LEXEDIR
export g09error=""
GAOPT

my $g09exe="g09";

my $gaussLog=$gaussFile;
#$gaussLog =~ s/\.com$/.log/;
$gaussLog =~ s/\.com$//;
print SCRIPT "export GAUSS_LOG=\"$gaussLog-\${GAUSS_JOBID}.log\" \n";


#Echo controlling PC
print SCRIPT "\necho -n \"Master Process is on: \"\n", "hostname\n";
print SCRIPT "\necho -n \"Machine details are: \"\n", "uname -a\n";
print SCRIPT "echo \"Local Working Directory: \$GAUSS_SCRDIR\"\n";
print SCRIPT "echo \"Server Directory: \$GAUSS_USER\"\n";
print SCRIPT "echo \"Log File is: \$GAUSS_LOG\"\n";


# Linda Options	
if ($numNodes > 1){
	my $lindaNodes=$numNodes-1;
	print SCRIPT <<LINDA;

\# Generate Nodes File
cat \$PBS_NODEFILE | sort | uniq >  \$GAUSS_SCRDIR/.nodes.\$GAUSS_JOBID
export GAUSS_LFLAGS=\"-v -n $lindaNodes -nodefile \$GAUSS_SCRDIR/.nodes.\$GAUSS_JOBID\"

\# Linda Environment settings
export GAUSS_EXEDIR=\"\$GAUSS_LEXEDIR:\$GAUSS_EXEDIR\"

UNIQNODES=\`cat \$PBS_NODEFILE|sort|uniq|tr '\\n' ' ' \`
echo "Machines: \$UNIQNODES"

LINDA

} 



print SCRIPT <<LINDA;
\# Main Program Run
date 
time $g09exe <\$GAUSS_USER/$gaussFile &> \$GAUSS_USER/\$GAUSS_LOG 
date

LINDA


# Manual Email
# Am not receiving emails sent through nodes using following

print SCRIPT "\n\# Email finish report\n",
	'/usr/bin/perl -e "print \"Your job $GAUSS_JOBID in queue $PBS_QUEUE has finished.\n', 
	"$gaussFile in folder \$GAUSS_USER completed at `date`\\n\$g09error\\n\\\",",
	"\\\`tail -10 \$GAUSS_LOG\\\`, \\\"\\n",
	"\\\";\" \\\n| /bin/mail -s \"Job \$GAUSS_JOBID Completed\" $EMAIL",
	"\n\n";
	
print SCRIPT 'echo "Finished job $GAUSS_JOBID"';
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


