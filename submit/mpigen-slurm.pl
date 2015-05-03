#!/usr/bin/perl -w
########################################
# Perl script for generating MPI submission scripts
#
# Generates Slurm settings submit file for MPI 
#  based on program number of procs given.
#
# Written by James Rudd, james.rudd@gmail.com
# 2015-04-30
# Tracking now done by GIT
########################################
use strict; use warnings;
use File::Basename;

die "Usage: $0 program [NumNodes]\ne.g. $0 vasp.g 2\n" unless (@ARGV >= 1);
print "MPI submission script generation\n";

sub CheckSettings($); 

MAIN:

#set defaults or load in file
my $gScratch="/state/partition1"; # or "\$TMPDIR"
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.MPISLURM";

my $file=$ARGV[0];
my $numNodes = 1;
$numNodes=$ARGV[1] if (@ARGV >= 2);

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
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Fast Debug Jobs on 40 core Dell FC630'
	    },
	'2'   =>  {
	    'name' => 'Mem128',
	    'queue' => 'Mem128',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '125000',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Small Memory Jobs on 40 core Dell FC630 w/ 128GB Ram'
	    },
	'3'   =>  {
	    'name' => 'Mem256',
	    'queue' => 'Mem256',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '245000',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Medium Memory Jobs on 40 core Dell FC630 w/ 256GB Ram'
	    },
	'4'   =>  {
	    'name' => 'Mem512',
	    'queue' => 'Mem512',
	    'cpu' => 40,
	    'par' => 1,
	    'maxmem' => '500000',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Large Memory Jobs on 40 core Dell FC630 w/ 512GB Ram'
	    }
);


# Data Checks
die "$numNodes is not a number\n" if ($numNodes =~ /\D/);
$numNodes = 1 if ($numNodes <2); #Need at least 2 to use MPI

#read in defaults
if ( -f $CONFIGFILE){
	print "\tLoading config file $CONFIGFILE\n";
	open CONFIG, " < $CONFIGFILE" or last;
	foreach my $line (<CONFIG>){
		chomp $line;
		next if ($line =~ /^#/);
		
		if ($line =~ /^PROCSHAREDOD[\s]*=[\s]*([\d]+)/i){
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
	$numNodes = 1 if ($numNodes <2); #Need at least 2 to use MPI
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
\#SBATCH -p $queues{$queueSelect}{'queue'}

\# Memory Requirments (Max mem=80gb,vmem=40gb)
\# This sets a hard memory limit within the shell. 
\# If not set defaults to 1GB
\# Increase if g09 returns galloc errors 
\#SBATCH --mem=$queues{$queueSelect}{'maxmem'}
\# Number of Nodes
\#SBATCH -N $numNodes
\# use --exclusive to get the whole nodes exclusively for this job
\# If you only need a few cores disable this and instead use -n
\#SBATCH --exclusive
\# Processor total (proc / node * \# nodes)
\#SBATCH -n $numCores
\# Tasks per node
\# SBATCH --ntasks-per-node=12
\# How long will it run [[HH:]MM:]SS, use UNLIMITED for no limit
\#SBATCH --time=8:00:00

SLURMSET


if ($EMAIL){
print SCRIPT "\# Notify these e-mail addresses.\n",
	"\#SBATCH --mail-user=$EMAIL\n",
	"\# Define mail notification events.\n",
	"\#SBATCH --mail-type=$EMAILNOTIFY\n",
}

# Gauss Options

print SCRIPT  <<GAOPT;
echo "Working directory is:"
pwd
source /etc/profile

\# Loads Gaussian application directory
module load $queues{$queueSelect}{'module'}

export TMPDIR=\"$gScratch/\$USER.\$SLURM_JOB_ID\"
export GAUSS_JOBID=\$SLURM_JOB_ID
export GAUSS_USER=\$SLURM_SUBMIT_DIR
export TSNET_PATH=\$GAUSS_LEXEDIR
export g09error=""
export OMP_NUM_THREADS=1
GAOPT


#Echo controlling PC
print SCRIPT <<CONFIGENVIRO;
echo -n "Master Process is on: "
hostname

echo -n "Machine details are: "
uname -a
echo "Local Working Directory: \$TMPDIR"


echo "Creating scratch directory on nodes"
srun --ntasks-per-node=1 mkdir -p \$TMPDIR
srun --ntasks-per-node=1 chgrp users \$TMPDIR 
srun --ntasks-per-node=1 chmod 2775 \$TMPDIR

CONFIGENVIRO

# Linda Options	
if ($numNodes > 1){

	print SCRIPT <<MPI;
\# Show Nodes List

echo "Machines: \$SLURM_NODELIST "
export NODES=\$(scontrol show hostnames \$SLURM_NODELIST | sort -u)


MPI

} 

print SCRIPT <<MPIPROG;
\# Main Program Run
date 
time srun $file 
date

\# Clean up scratch
srun --ntasks-per-node=1 rm -rf \$TMPDIR

MPIPROG


# Manual Email
print SCRIPT "\n\# Email finish report\n",
	'/usr/bin/perl -e "print \"Your job $SLURM_JOB_ID in queue $SLURM_JOB_PARTITION has finished.\n', 
	"$file in folder \$SLURM_SUBMIT_DIR completed at `date`\\n\\\",",
	"\\\";\" \\\n| /bin/mail -s \"Job \$SLURM_JOB_ID: $file   Completed\" $EMAIL",
	"\n\n";
	
print SCRIPT 'echo "Finished job $GAUSS_JOBID"';
close SCRIPT;


