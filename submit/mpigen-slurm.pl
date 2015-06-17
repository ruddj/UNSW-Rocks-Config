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
my $userName =  $ENV{'LOGNAME'};
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.MPISLURM";

my $file=$ARGV[0];
my $numNodes = 1;
$numNodes=$ARGV[1] if (@ARGV >= 2);

my $PROCSHARED=20; # how many processors for each PC
my $PROCSHAREDOD=1; #overide value

my $EMAILNOTIFY="FAIL";
my $EMAIL="$userName\@unsw.edu.au";

# Queues

my $queueSelect = 1;

my %queues = (
	'1' =>  {
	    'name' => 'debug',
	    'queue' => 'debug',
	    'cpu' => 20,
	    'par' => 0,
	    'maxmem' => '100000',
		'deftime' => '00:30:00',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Fast Debug Jobs on 20 core Dell FC630'
	    },
	'2'   =>  {
	    'name' => 'Mem128',
	    'queue' => 'Mem128',
	    'cpu' => 20,
	    'par' => 1,
	    'maxmem' => '125000',
      'deftime' => '04:00:00',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Small Memory Jobs on 20 core Dell FC630 w/ 128GB Ram'
	    },
  '3'  =>  {
      'name' => 'Mem128s',
      'queue' => 'Mem128s',
      'cpu' => 20,
      'par' => 1,
      'maxmem' => '125000',
      'deftime' => '04:00:00',
      'module' => 'pgi openmpi/pgi',
      'desc' => 'Small Memory Jobs on 20 core Dell FC430 w/ 128GB Ram'
       },
	'4'   =>  {
	    'name' => 'Mem256',
	    'queue' => 'Mem256',
	    'cpu' => 20,
	    'par' => 1,
	    'maxmem' => '245000',
		'deftime' => '08:00:00',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Medium Memory Jobs on 20 core Dell FC630 w/ 256GB Ram'
	    },
	'5'   =>  {
	    'name' => 'Mem512',
	    'queue' => 'Mem512',
	    'cpu' => 20,
	    'par' => 1,
	    'maxmem' => '500000',
		'deftime' => '08:00:00',
	    'module' => 'pgi openmpi/pgi',
	    'desc' => 'Large Memory Jobs on 20 core Dell FC630 w/ 512GB Ram'
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
			if ($line =~ /^EMAILNOTIFY[\s]*=[\s]*(BEGIN|END|FAIL|REQUEUE|ALL)[\s]*(#|$)/i){ 
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
#EMAILNOTIFY=FAIL 	# Notify actions for email
#EMAIL=$userName\@unsw.edu.au	# Email address to send to

#Following sets options inside Gaussian file
#MEM=20gb 		# Set the memory / CPU
#MEMOD=0 		# Overide the memory value
PROCSHARED=20		# Use this many shared processors in Gaussian File
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
\# SBATCH --ntasks-per-node=$PROCSHARED
\# How long will it run [[HH:]MM:]SS, use UNLIMITED for no limit
\#SBATCH --time=$queues{$queueSelect}{'deftime'} 

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

\# Loads MPI modules
module load $queues{$queueSelect}{'module'}

export OMP_NUM_THREADS=1
GAOPT


#Echo controlling PC
print SCRIPT <<CONFIGENVIRO;
echo -n "Master Process is on: "
hostname

echo -n "Machine details are: "
uname -a
echo "Local Working Directory: \$TMPDIR"

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
time mpirun --bind-to core  $file 
date

MPIPROG


# Manual Email
print SCRIPT "\n\# Email finish report\n",
	'/usr/bin/perl -e "print \"Your job $SLURM_JOB_ID in queue $SLURM_JOB_PARTITION has finished.\n', 
	"$file in folder \$SLURM_SUBMIT_DIR completed at `date`\\\"; \" \\\n",
	"| /bin/mailx -s \"Job \$SLURM_JOB_ID: $file Completed\" $EMAIL",
	"\n\n";
	
print SCRIPT 'echo "Finished job $SLURM_JOB_ID"';
close SCRIPT;


