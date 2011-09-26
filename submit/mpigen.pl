#!/usr/bin/perl -w
########################################
# Perl script for generating MPI submission scripts
#
# Generates a default submit-file.sh file for MPI orte 
#  based on program number of procs given.
#
# Written by James Rudd, james.rudd@gmail.com
# 20090420
# Tracking now done by GIT
########################################
use strict; use warnings;
use File::Basename;

die "Usage: $0 program [NumNodes]\ne.g. $0 vasp.g 2\n" unless (@ARGV >= 1);
print "MPI submission script generation\n";

sub CheckSettings($); 

MAIN:

#set defaults or load in file
#my $G03ROOT="/gaussian";
#my $gScratch="/state/workspace"; # or "\$TMPDIR"
my $home=`echo \$HOME`;
chomp($home);
my $CONFIGFILE="$home/.G03SGE"; # Uses Gaussian config for email address settings

my $numNodes = 1;
$numNodes=$ARGV[1] if (@ARGV >= 2);

my $PROCSHARED=4; # how many processors for each PC
my $PROCSHAREDOD=1; #overide value

my $EMAILNOTIFY="beas";
my $EMAIL="dirk.koenig\@unsw.edu.au";

my $file=$ARGV[0];


# Data Checks
die "$numNodes is not a number\n" if ($numNodes =~ /\D/);
#$numNodes = 0 if ($numNodes <2); #Need at least 2 to use linda

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
my $submitfile = "submit-$file.sh";
open SCRIPT, "> $submitfile" or die "Could not create file";

print "\tCreating SGE submit file: $submitfile\n";

my $queueAllo;
if ($numNodes) {
        print "\t\twith $numNodes nodes and $numCores cores.\n";
        $queueAllo = "\# Use Parallel Queue (sequence: dell.pe1,dell.pe2,compute.q)\n\# You must include masterq queue in this list\n";
        $queueAllo .= "\#\$ -q dell.pe1,dell.pe2,compute.q\n";
        $queueAllo .= "\# The master process must run on a node in this queue(either dell.pe1 or dell.pe2)\n# Use dell.pe2 if you do not have rights to dell.pe1\n";
        $queueAllo .= "\#\$ -masterq dell.pe1,dell.pe2\n";
        $queueAllo .= "\# \n\# Setting gauss=0 allows slave calculations to run on nodes already doing calculations.\n#  \$ -l gauss=0";
}
else {
        print "\t\twith 1 node\n";
        $queueAllo = "\# Use the Standard Queues (can be compute.q,single.q,single.ql)\n\#\$ -q compute.q,single.q,single.ql";
}
print "\tCheck generated file and submit with 'qsub $submitfile'\n";

# SGE Options
print SCRIPT <<SGESET;
\#!/bin/bash

\# Grid Engine Settings 
\# Grid engine reads in any line beginning with \#\$ as a qsub argument.
\# You can comment out a SGE command by putting a space between \#\$, so \# \$
\# Some commands below are already commented out. If you wish to use them remove the space.
\#
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
\# Force excution on a specific node (Optional)
\#  \$ -l hostname="compute-0-?"
SGESET


if ($EMAIL){
print SCRIPT "\# Notify these e-mail addresses.\n",
	"\#\$ -M $EMAIL\n",
	"\# Define mail notification events.\n",
	"\# [e]nd, [b]eginning, [a]bort, [n]ever mail, [s]uspension\n",
	"\#\$ -m $EMAILNOTIFY\n",
}

print SCRIPT "\# Request processors for parallel jobs.(nodes * proc/node)\n",
	"\# Change number to adjust number of cores.\n",
	"\#\$ -pe orte " . $numCores ."\n";


# Gauss Options

print SCRIPT  <<VASPOPT;

echo "Working directory is:"
pwd
VASPWD=`pwd`
\# MPI Environment settings
source /etc/profile

#Load variables and settings
# Load PGI Libraries and OpenMPI for communication
module load pgi openmpi/pgi 

# Loads application directory, 
#  required to add application directory to PATH 
# To see a list of applications type "module avail"

module load vasp
#module load nanophonon
#module load espresso

VASPOPT


#print SCRIPT "export VASP_LOG=\"$file-\${JOB_ID}.log\" \n";


#Echo controlling PC
print SCRIPT "\necho -n \"Master Process is on: \"\n", "hostname\n";
print SCRIPT "\necho -n \"Machine details are: \"\n", "uname -a\n";
print SCRIPT "echo \"Working Directory: \"\n", "pwd\n";
#print SCRIPT "echo \"Server Directory: \$GAUSS_USER\"\n";
#print SCRIPT "echo \"Log File is: \$VASP_LOG\"\n";

# Linda Options	
# May need to add commands to create scratch directories on nodes using SSH
# may also need to sort node list so Master started on highmem pcs
if ($numNodes){

	print SCRIPT <<LINDA;
	
\# Read in Node List 
export NODES=\`awk \'{print \$1 }\' \$PE_HOSTFILE\`

echo "Got \$NSLOTS processors."
echo "Machines: \$NODES"

LINDA

} 

print SCRIPT "\# Main Program Run\n";

print SCRIPT "date\n", 
	"time mpirun -np \$NSLOTS $file \n", 
	"date\n";

# Manual Email
# Am not receiving emails sent through nodes using following

print SCRIPT "\n\# Email finish report\n",
	'perl -e "print \"Your job $JOB_ID in queue $QUEUE is done\n', 
	"$file in folder \$VASPWD completed at `date`\\n\\\",",
	"\\\`tail -10 \$VASP_LOG\\\`, \\\"\\n",
	"\\\";\" \\\n| /bin/mail -s \"Job \$JOB_ID: $file Completed\" $EMAIL",
	"\n\n";
	
print SCRIPT 'echo "Finished job $JOB_ID"';
close SCRIPT;


