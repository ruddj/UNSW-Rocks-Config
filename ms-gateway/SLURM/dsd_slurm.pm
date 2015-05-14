#****************************************************************************
#
# File: dsd_slurm.pm
#
# Description: # Implementation of SLURM control class
#  
# Orginator:  vadim    2002
# 
# Copyright (C) 2002 Accelrys, Inc., All Rights Reserved
# Modified for slurm by JR, 2015
#****************************************************************************

use strict;

use DSD_utils;
use DSD_errors;
use DSD_defaults;

package  dsd_slurm;
use Error qw(:try);

BEGIN
{
    our $cfgname="slurm";
    our	@ISA='DSD_basequeue';
    use base ("DSD_basequeue");

    use constant QSTAT_RC_JOB_NOT_FOUND => 153;

# Constants to configure how the gateway should behave for qstat failures.
# It is possible that qstat can fail on a heavily loaded system even when 
# there is no fundamental problem with the queuing system. The gateway ignores
# errors when calling qstat for job status assuming that there is an intermittant
# problem. To avoid real queuing failures to cause jobs to sit permanently in the
# running state whilst in fact there has been a failure, the following two constants 
# allow the behaviour to be tuned appropriately to a particular SLURM installation.

# The minimum number of times that qstat calls must fail consecutively to
# consider failing the job. If negative, no jobs will fail. If zero, the
# number of consecutive failures is not taken into account. 
    use constant QSTAT_MINIMUM_CONSECUTIVE_FAILED_CALLS => 3;

# The minimum time since the job started or the last successful call to qstat
# before considering failing the job. If negative, no job will fail. If zero,
# the time taken since the last failure is not taken into account.
    use constant QSTAT_MINIMUM_FAILED_PERIOD => (30 * 60); # ie 30 minutes

#location of the queue binaries - otherwise should be in the path
    my $bin_location='/usr/bin/'; #'/usr/local/bin/';


#start the job
    sub Submit($$$$;$$)
    {
	my $qsub = $bin_location."sbatch";
	my $cmd="slurm.sh";
	
	my ($myself,$executable,$args,$dir,$spriority,$queue_priority) = @_;
	my $myloc=DSD_basequeue::MyLocation($myself);
	my $success;

        if($DSD_defaults::dsd_isNT)
        {
            $cmd ="slurm.bat";
            if (!($executable =~ /^\"/) &&  ($executable =~ /\s/g))
            {
                $executable = "\"$executable\"";
            }
            # some of this can be URL-encoded, so need to escape the %'s
            $executable =~ s/%/%%/g;
            $args =~ s/%/%%/g;
        }

	my $jobid = DSD_utils::get_jobid($dir);

	my $queueName = $DSD_basequeue::G_working_queue;
	$queueName = GetDefaultQueue($myself) unless $queueName;

	
	my $jobName = "MS_$jobid";

	my $queueParams = ( (defined $queueName) ? "-p $queueName" : "" );

	#any additional parameters ?
	my $params = DSD_basequeue::get_config_info_item ('params', "$myloc/${cfgname}.cfg");
	$params = " --job-name=$jobName $params " if ($jobid);
	my $cpu = DSD_utils::get_jobinfoitem('job-cpu-number', $jobid,	1); # reverse search

	my $queueExtraParams = $DSD_basequeue::G_queueExtraParams;
	$queueExtraParams =~s/%n%//g;
	$params .= " $queueExtraParams ";

	if($cpu){
	    my $cpuspernode = DSD_basequeue::get_config_info_item ('NumCPUSsperNode', "$myloc/${cfgname}.cfg");
	    $params .= GetResourceLine($cpu,$cpuspernode);
	}

	$args =~ s/\s-nolocal\s/ /; # do not use mpi -nolocal 

	my $qsubCmd = "$qsub $params $queueParams $cmd";
	
	if(open (my $CMD, ">$cmd"))
	{
	    # Create a script to submit to the queue
	    my $header=DSD_basequeue::FormShellHeader($myself,$dir,"$myloc/${cfgname}.cfg",$qsubCmd,$cpu);
	    print( $CMD $header);

	    # Make sure that current TMPDIR env variable value is not lost
	    # since SLURM will supply its own suggested value - which is not 
	    # necessarily accessible from all of the nodes in a multi-node
	    # job (and if it were to be accessible, it would be on a non-local
	    # drive and so not as efficient as a drive local to each node.
	    if ($ENV{'TMPDIR'})
	    {
                if( $DSD_defaults::dsd_isNT )
                {
                    print( $CMD "REM Ensure that TMPDIR value is not lost\n" );
                    print( $CMD "set TMPDIR=\"$ENV{'TMPDIR'}\"\n" );
                    print( $CMD "set PBS_TMPDIR=\"$ENV{'TMPDIR'}\"\n" );
                }
                else
                {
                    print( $CMD "# Ensure that TMPDIR value is not lost\n" );
                    print( $CMD "PBS_TMPDIR=\"\$TMPDIR\"\n" );
                    print( $CMD "export PBS_TMPDIR\n" );
                    print( $CMD "TMPDIR=\"$ENV{'TMPDIR'}\"\n" );
                    print( $CMD "export TMPDIR\n" );
                }
	    }
		
		# set path in bat file
		if ( $DSD_defaults::dsd_isNT )
		{
			print( $CMD "set PATH=$ENV{'Path'}\n") ;
		}

	    print( $CMD $executable) ;
	    print( $CMD " $args\n");

	    close $CMD;
	    chmod 0755, $cmd;

	    if (open(my $QSUB, "$qsubCmd 2>&1|")) 
	    {
		my @out = <$QSUB>;
		close ($QSUB);

		if(@out[0] =~ m/\d$/) ##first digit , OK !
		{
		    $DSD_basequeue::G_id = $out[0];
		    $DSD_basequeue::G_status =  DSD_basequeue::QJOB_STARTED;
		}
		else
		{
		    my $out;
		    my $count = 0;
		    foreach	(@out)
		    {
			chomp($_);
			$out = "$out $_";
			$count++;
			last unless ($count < 5); ## no more then 5 lines
		    }
                    DSD_utils::throw($DSD_errors::QUEUE_GENERAL_ERROR, 
                                     sprintf($DSD_errors::QUEUE_GENERAL_ERROR_TEXT,$out));
		}
	    }
	    else
	    {
		DSD_utils::throw($DSD_errors::GENERAL_EXEC_ERROR,
				 sprintf($DSD_errors::GENERAL_EXEC_ERROR_TEXT,$qsub, $!));
	      }
	}
	else
	{
	    DSD_utils::throw($DSD_errors::CANNOT_CREATE_OPEN_FILE,
			     sprintf($DSD_errors::CANNOT_CREATE_OPEN_FILE_TEXT,$cmd, $!));
	  }
	chomp($DSD_basequeue::G_id);
	
	DSD_utils::add_job_info_message($jobid, DSD_basequeue::QJOB_ITEM_JOBID, $DSD_basequeue::G_id);
	DSD_utils::add_job_info_message($jobid, DSD_basequeue::QJOB_ITEM_JOBNAME, $jobName);
	DSD_utils::add_job_info_message($jobid, DSD_basequeue::QJOB_ITEM_QUEUENAME, $queueName);
	
	return $DSD_basequeue::G_id;	
    }


sub detectPBSAndVersion() 
{
    my ($ran, $rc, @stdoutFile, @stderrFile);	
    my $ispbs = 0;
    my $version;
    ($ran, $rc) 
	= DSD_basequeue::runAndReturnOutputs($bin_location. "sinfo --version",\@stdoutFile, \@stderrFile);
    if($ran){
	foreach (@stdoutFile,@stderrFile){
	    if (/slurm (.*)/i){
		($version) = "SLURM ".$1;
		$ispbs = 1;
	    }
	}
    }
    return ($ispbs,$version);    
}

sub Detect()
{
    return 1 if DSD_basequeue::get_config_info_item (DSD_basequeue::AlwaysReportPresence,DSD_basequeue::MyLocation(shift)."/${cfgname}.cfg");

    my ($Present, $Version) = detectPBSAndVersion();
    return $Present;	
}

sub GetDescription()
{
    return ${cfgname} if  DSD_basequeue::get_config_info_item (DSD_basequeue::AlwaysReportPresence,DSD_basequeue::MyLocation(shift)."/${cfgname}.cfg");

my ($Present, $Version) = detectPBSAndVersion();
    return $Version;	
}



# Check the job status
sub GetJobStatus($;$)
{
    my ($myself, $_id)=@_;
    my($shortId,$name,$user,$use,$status,$queue);
    $_id=$DSD_basequeue::G_id unless defined($_id);
    my $qstat = $bin_location. "squeue -h -j " . $_id . " -o \"%i %T\"";
;
    
    my($couldRun, $rc, @stdoutFile, @stderrFile);    
    ($couldRun, $rc) 
	= DSD_basequeue::runAndReturnOutputs($qstat, \@stdoutFile, \@stderrFile);
    if ($couldRun)
    {
	
	#my ( $G_numid, @rubbish) = split '\.', $_id; 
	foreach my $line (@stdoutFile) {
	    ($shortId,$status) = split /\s+/, $line;
	    my ($numid,@rubbish) = split '\.', $shortId; 
	    if($_id eq $numid ){
			# Found!
			if( ($status eq "PENDING")) 
			{
				return DSD_basequeue::QJOB_QUEUED; 
			}
			if(($status eq "RUNNING") || ($status eq "COMPLETING")) #"E" exiting . Should it be here ?
			{
				return DSD_basequeue::QJOB_RUNNING; 
			}
			if( ($status eq "COMPLETED")) #"C" exiting
			{
				return DSD_basequeue::QJOB_FINISHED; 
			}
			if( ($status eq "SUSPENDED")) 
			{
				return DSD_basequeue::QJOB_PAUSED; 
			}
			if( ($status eq "CANCELLED"))
			{
				return DSD_basequeue::QJOB_STOPPED; 
			}
			if( ($status eq "FAILED") || ($status eq "TIMEOUT"))
			{
				return DSD_basequeue::QJOB_FAILED; 
			}
			return  DSD_basequeue::QJOB_STARTED;
	    }
	}
	
    }
    elsif ($rc eq +QSTAT_RC_JOB_NOT_FOUND)
    {
	# Based on rc value, job has completed and been removed from the job list
	return DSD_basequeue::QJOB_FINISHED;
    }
    else
    {
	# In this case we must have got some sort of error
	# The job has not finished because that would have been 
	# picked up in the earlier test of return code, so we have
	# an unknown error, such as loss of communication between
	# client node and the queue master node.
	# We should add an UNKNOWN state for this case, but for now 
	# use RUNNING so that the client doesn't lose track of the job

	# 23/Jul/2009 aperlov: added unknown

	return DSD_basequeue::QJOB_STATUS_UNKNOWN;

    }
    
}


# When to use queue: when starting the script or execuatable
# should return one of the "using queue" constants (see at the top)
sub WhenToStart(;$)
		{
		    return DSD_basequeue::QUEUE_EXE;
		}		

# Delete the job from the queue
sub Stop($;$)
{
    my($myself,$pid) =@_;
    $pid=$DSD_basequeue::G_id unless defined($pid);
    my $success;
    my $qdel = $bin_location."scancel";
    if (open(my $QDEL, "$qdel $pid|")) 
    {
	close($QDEL);
	$DSD_basequeue::G_status = DSD_basequeue::QJOB_STOPPED;
    }
    else
    {
	DSD_utils::throw($DSD_errors::GENERAL_EXEC_ERROR,
			 sprintf($DSD_errors::GENERAL_EXEC_ERROR_TEXT,$qdel, $!));
      }
    return $success;	
};


sub GetAvailableQueues($$;$)
{ 
    my ($self, $user ,$error) = @_;
    my $def_queue = GetDefaultQueue($self);
    my @names;
    push @names,$def_queue;
    if (open(my $QSTAT, "$bin_location" . "sinfo -h -o \"%R\" |")){
	foreach (<$QSTAT>){
		my $qn=$_;
		$qn=~s/^\s+|\s+$//g;		
		push @names, $qn if $qn ne $def_queue;
	}
    }
    return @names;
}


sub GetDefaultQueue($)
{
    my ($myself) = @_;
    my $myloc=DSD_basequeue::MyLocation($myself);
    my $default_queue = DSD_basequeue::get_config_info_item ("default_queue","$myloc/${cfgname}.cfg");
    if( !$default_queue && (open (my $QMGR, 'sinfo -h -o \"%P\"  |')))
    {
	my @lines = <$QMGR>;
	close ($QMGR);
	foreach my $line (@lines)
	{
	    $line =~ s/\s//g;
		$_ = $line;
	    if (/([^\*]+)\*/)
	    {
		$default_queue = $1;
		last;
	    }
	}
    }
    return $default_queue;
}


sub GetResourceLine(){
    my $cpu=shift;
    my $cpuspernode = shift;
    if (!$cpuspernode){
	$cpuspernode=EstimateCPUperNode();
    }
    my $line=" -N ";
    my $mod=$cpu % $cpuspernode;
    my $full=($cpu-$mod)/$cpuspernode;
    if($full){
	$line.="$full -n $cpu";
    }
    else{
	$line.="1 -n $cpu";
    }
    
}
sub EstimateCPUperNode()
{

    my $numpr=10000;
    my ($ran, $rc, @stdoutFile, @stderrFile);	
    my $ispbs = 0;
    my $version;
    ($ran, $rc) 
	= DSD_basequeue::runAndReturnOutputs($bin_location. "sinfo -h -o \"%c\"",\@stdoutFile, \@stderrFile);
    if($ran){	
	foreach (@stdoutFile){
	    $numpr = $_;
	}
    }
    $numpr =1 if ($numpr==10000);
    return $numpr; 
}

sub GetCfgValue
{

    my ($myself,$variable) = @_;
    my $myloc=DSD_basequeue::MyLocation($myself);
    my $value = DSD_basequeue::get_config_info_item($variable,"$myloc/${cfgname}.cfg");
    return $value;

}
  

sub CreateMachineFileCommand
{
   # my $command="cat \$PBS_NODEFILE";
	my $command = $bin_location . "scontrol show hostnames \$SLURM_NODELIST";
	
    return $command; 
}

} #BEGIN

1;
