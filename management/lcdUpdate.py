#!/usr/bin/python
import os

# Tanner Stokes - tannr.com - 2-26-10
# This script changes the LCD user string on Dell machines that conform to IPMI 2.0

#sp_hostname = raw_input ("\nEnter DNS or IP of SP: ");
#user_string = raw_input("Enter LCD string: ")

#user_string = os.system('/bin/hostname -s')
from socket import gethostname
user_string = gethostname().split('.')[0]

hex_string = ""

for x in user_string:
 	hex_string += hex(ord(x))
	# add space between each hex output
	hex_string += " "

print '\nTrying to change LCD string on '+user_string+'...'

#return_val = os.system('/usr/sbin/ipmitool -H '+sp_hostname+' -I lan -U root raw 0x6 0x58 193 0 0 '+str(len(user_string))+' '+hex_string)
return_val = os.system('/usr/bin/ipmitool raw 0x6 0x58 193 0 0 '+str(len(user_string))+' '+hex_string)

print 'ipmitool raw 0x6 0x58 193 0 0 '+str(len(user_string))+' '+hex_string

if (return_val == 0):
	print 'LCD string changed successfully.\n'
else:
	print '\nNon-zero return value, something went wrong.'
	print 'Make sure IPMI is enabled on the remote host and the DNS or IP is correct.\n'

# this function supposedly sets the user string to show on the LCD, but never got it to work
# this can be changed from the front of the box anyway
os.system('/usr/bin/ipmitool raw 0x6 0x58 194 0')
