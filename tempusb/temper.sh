#!/bin/bash

# This script will check the temperature of the TemperUSB adaptor
# When temperature reaches warning level it will send an email
# When it reaches critical it will execute a shutdown command
# Based on code from https://wwwx.cs.unc.edu/~hays/dev/bash/temper/check_temper

# Temperatures
WARNTEMP=30;
HIGHTEMP=35;
DELTATEMP="2.0"; # Used to trigger warning email due to rapid temperature rise.

# Calibration, How much should be added to value? Can be negative.
MODTEMP=0.0

# Commands
SHUTDOWNCMD="echo Shutdown"
PCSENSORS="/home/ruddj/UNSW-Rocks-Config/tempusb/pcsensor-1.0.0/pcsensor"
MAILREPORT="james.rudd@unsw.edu.au"

# Data Store
CHECKFILE=/usr/tmp/temper.data

umask 0033

# Check to see that we have a program to read the temp
if [[  ! -f ${PCSENSORS} ]] ; then
   echo "${PCSENSORS} not found";
   echo "Error: Could not find ${PCSENSORS}" | mailx -s "PC Sensor program missing on $HOSTNAME" $MAILREPORT
   exit 1;
fi

# Initialize values
if [[  -f ${CHECKFILE} ]] ; then
   source ${CHECKFILE}
fi

if [ ! -w ${CHECKFILE} ] ; then
	echo "Cannot save to ${CHECKFILE}. Please check permissions"
	echo "Error: Could not write to ${CHECKFILE}" | mailx -s "PC Sensor can not save on $HOSTNAME" $MAILREPORT
	exit 2;
fi

# Clear status after every run
echo "# Temperature Monitoring Status Files" > ${CHECKFILE} 

# Check program returns real value
tempReturn=$(${PCSENSORS} -m);
returnValue=$?

# Check sensor connected 
if [[ ${tempReturn} == *"Exiting"* ]] ; then
	# Couldn't find the USB device, Exiting
	
	# Check if message already sent	
	if [[ -z $NOPROBEEMAIL ]] ; then
		# Send message about disconnected sensor
		echo "Error: ${tempReturn}" | mailx -s "Temp Sensor Missing on $HOSTNAME" $MAILREPORT
	fi
	echo "NOPROBEEMAIL=sent" >> ${CHECKFILE} 
	exit 3;
elif [[ $returnValue > 0 || ${tempReturn} == *"failed"* ]] ; then
	# USB interrupt read: Resource temporarily unavailable \n Fatal error> USB read failed
	# Exit error 17
	
	# Could not read sensor. Wait until next cycle and if still problem send email.
	echo "PROBEFAILED=1" >> ${CHECKFILE} 
	
	if [[ ${PROBEFAILED} -ge 1 ]] ; then
		# Check if message already sent	
		if [[ -z $PROBEFAILEDEMAIL ]] ; then
			# Send message about error sensor
			echo "Error: ${tempReturn}" | mailx -s "Temp Sensor Failed Read on $HOSTNAME" $MAILREPORT
		fi
		echo "PROBEFAILEDEMAIL=sent" >> ${CHECKFILE} 
	fi
	exit 4;
fi

temp=$(echo ${tempReturn} | cut -f1 -d' ' )
temp=$( echo "${temp} + ${MODTEMP} " | bc )

echo "PREVTEMP=${temp}" >> ${CHECKFILE} 

# Check the temperature to see what it is
# if it's above the hightemp or warningtemp
# see the appropriate message.
if [[ ${temp} > ${HIGHTEMP} ]]
  then
  message="Critical: ";
  error_code=2;
  
  if [[ ${error_code} == ${LASTLEVEL} ]] ; then
	# Same warning twice in row
	
	# Perform shut down
	echo "Shutdown: Critical temperature of ${temp}c > ${HIGHTEMP} reached. Shutting down cluster" | mailx -s "Critical Temp Start Shutdown on $HOSTNAME at ${temp}c" $MAILREPORT
	SHUTDOWNMSG=$(${SHUTDOWNCMD})
	echo "Shutdown: ${SHUTDOWNMSG}" | mailx -s "Critical Temp Shutdown Complete on $HOSTNAME at ${temp}c" $MAILREPORT
  fi
elif [[ ${temp} > ${WARNTEMP} ]]
  then
  message="Warning: ";
  error_code=1;
  
  if [[ ${error_code} == ${LASTLEVEL} ]] ; then
	# Same warning twice in row
	
	# Record that warning sent so do not send again. If rapid increase in temper then send again.
	if [[ -z $WARNINGEMAIL || $( echo "${temp} > ${PREVTEMP} + ${DELTATEMP}" | bc ) -eq 1 ]] ; then
		# Send message about temperature level
		echo "Warning: Temperature at ${temp} on $HOSTNAME" | mailx -s "Warning Temp Sensor on $HOSTNAME" $MAILREPORT
	fi
	echo "WARNINGEMAIL=sent" >> ${CHECKFILE}   
  fi
else 
	#echo "Normal Temp Sensor: ${temp}";
	message="Normal: ";
	error_code=0;
  	if [[ -n $WARNINGEMAIL ]] ; then
		# Send message about disconnect sensor
		echo "Normal: Temperature at ${temp} on $HOSTNAME" | mailx -s "Normal Temp Reading on $HOSTNAME" $MAILREPORT
	fi
fi
# Record warning level
echo "LASTLEVEL=${error_code}" >> ${CHECKFILE} 


message="${message} Sensor Temp is ${temp} c";
echo ${message}

exit ${error_code};

