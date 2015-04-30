#!/usr/bin/perl -w
########################################
# Perl script for generating Slurm submission scripts
#
# Generates Slurm settings and sets defaults in 
# gaussian file
#
# Written by James Rudd, james.rudd@gmail.com
# 2015-04-30
# Tracking now done by GIT
########################################
use strict; use warnings;
use File::Basename;

die "Usage: g09gen GaussFileName [NumNodes]" unless (@ARGV >= 1);
print "Slurm submission script generation\n";

sub CheckSettings($); 

MAIN:

#set defaults or load in file
my $gScratch="/state/partition1"; # or "\$TMPDIR"
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.G09SLURM";
my $TSNET="$home/.tsnet.config";
my $gaussFile=$ARGV[0];
my $numNodes = 1;
$numNodes=$ARGV[1] if (@ARGV >= 2);

my $MEM="400MB";
my $MEMOD=0; #overide value
my $PROCSHARED=40; # how many processors for each PC
my $PROCSHAREDOD=1; #overide value

my $EMAILNOTIFY="ALL";
my $EMAIL="me\@unsw.edu.au";

# Queues

my $queueSelect = 1;

my %queues = (
	'1' =>  {
	    'name' => 'debug',
	    'queue' => 'debug',
	    'cpu' => 40,
	    'par' => 0,
	    'maxmem' => '100000',
	    'module' => 'g09/gbin',
	    'desc' => 'Fast Debug Jobs on 40 core Dell FC630'
	    },
	'2'   =>  {
	    'name' => 'Mem128',
	    'queue' => 'Mem128',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '125000',
	    'module' => 'g09/gbin',
	    'desc' => 'Small Memory Jobs on 40 core Dell FC630 w/ 128GB Ram'
	    },
	'3'   =>  {
	    'name' => 'Mem256',
	    'queue' => 'Mem256',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '245000',
	    'module' => 'g09/gbin',
	    'desc' => 'Medium Memory Jobs on 40 core Dell FC630 w/ 256GB Ram'
	    },
	'4'   =>  {
	    'name' => 'Mem512',
	    'queue' => 'Mem512',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '500000',
	    'module' => 'g09/gbin',
	    'desc' => 'Large Memory Jobs on 40 core Dell FC630 w/ 512GB Ram'
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
#Following sets Slurm Options
#EMAILNOTIFY=ALL 	# Notify actions for email
#EMAIL=me\@unsw.edu.au	# Email address to send to

#Following sets options inside Gaussian file
#MEM=20gb 		# Set the memory / CPU
#MEMOD=0 		# Overide the memory value
PROCSHARED=40		# Use this many shared processors in Gaussian File
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
my $submitFile = "submit-$file.slurm";
open SCRIPT, " > $submitFile" or die "Could not create file";

print "\tCreating Slurm file: $submitFile\n";

my $queueAllo;
if ($numNodes > 1) {
        print "\t\twith $numNodes nodes, $PROCSHARED cores/node, Total $numCores cores.\n";
}

# Slurm Options
print SCRIPT <<SLURMSET;
\#!/bin/bash

\# Slurm Settings
\# Slurm reads in any line beginning with \#SBATCH as a sbatch argument.
\# Specify job name.
\#SBATCH  --job-name="$file" 

\# Set partition
#SBATCH -p $queues{$queueSelect}{'queue'}

\# Memory Requirments (Max mem=80gb,vmem=40gb)
\# This sets a hard memory limit within the shell. 
\# If not set defaults to 1GB
\# Increase if g09 returns galloc errors 
\#SBATCH --mem=$queues{$queueSelect}{'maxmem'}
\# Number of Nodes
\#SBATCH -N $numNodes
\# Processor per node
\#SBATCH -n $PROCSHARED
\# How long will it run [[HH:]MM:]SS 
\# SBATCH --time=8:00:00

SLURMSET


if ($EMAIL){
print SCRIPT "\# Notify these e-mail addresses.\n",
	"\#SBATCH --mail-user=$EMAIL\n",
	"\# Define mail notification events.\n",
	"\#SBATCH --mail-type=$EMAILNOTIFY\n",
}

# Gauss Options

print SCRIPT  <<GAOPT;
cd \$SLURM_O_WORKDIR

echo "Working directory is:"
pwd
source /etc/profile

\# Loads Gaussian application directory
module load $queues{$queueSelect}{'module'}

export GAUSS_SCRDIR=\"$gScratch/\$USER.\$SLURM_JOB_ID
export GAUSS_JOBID=\$SLURM_JOB_ID
export GAUSS_USER=\$SLURM_SUBMIT_DIR
export TSNET_PATH=\$GAUSS_LEXEDIR
export g09error=""
export OMP_NUM_THREADS=1
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
	
\# Create scratch directories on nodes using srun
echo "Creating scratch directory on nodes"
srun "mkdir \$GAUSS_SCRDIR ; chgrp users \$GAUSS_SCRDIR ; chmod 2775 \$GAUSS_SCRDIR"

\# Generate Nodes File
LINDA_NODE_FILE=\$GAUSS_SCRDIR/.nodes.\$GAUSS_JOBID
echo -n "Machines: "
srun hostname -s | sort -u | tee \$LINDA_NODE_FILE
export GAUSS_LFLAGS=\"-v -n $lindaNodes -nodefile \$LINDA_NODE_FILE\"

\# Linda Environment settings
export GAUSS_EXEDIR=\"\$GAUSS_LEXEDIR:\$GAUSS_EXEDIR\"

LINDA

} 
else {
	print SCRIPT "mkdir \$GAUSS_SCRDIR ; chgrp users \$GAUSS_SCRDIR ; chmod 2775 \$GAUSS_SCRDIR";
}


print SCRIPT <<GAUSSPROG;
\# Main Program Run
date 
time $g09exe <\$GAUSS_USER/$gaussFile &> \$GAUSS_USER/\$GAUSS_LOG 
date

GAUSSPROG


# Manual Email
print SCRIPT "\n\# Email finish report\n",
	'/usr/bin/perl -e "print \"Your job $GAUSS_JOBID in queue $SLURM_JOB_PARTITION has finished.\n', 
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

print "Completed Slurm preperation\n";


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


