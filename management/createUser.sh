#!/bin/bash
 
# File to create a new user account
# Written by James Rudd, 2012-02-26

# Can use a loop for multiple users
NEW_REPEAT=1
 
# Need to find out username, full name and Email
NEW_USER=
NEW_NAME=
NEW_EMAIL=

echo "Welcome to James' Rocks create user script"
 
echo -n "Please enter user's full name: "
read -e NEW_NAME
echo -n "Please enter user's login account: "
read -e NEW_USER
# Error checking of username
if [ -z "${NEW_USER}" ]; then
	echo "Username is empty"
	exit 1
elif echo "${NEW_USER}" | egrep -q "[[:space:]]" ; then
	echo "Username can not contains spaces"
	exit 2
elif cut -d: -f1 /etc/passwd | fgrep -q "${NEW_USER}" ; then
	echo "Username already exists"
	exit 3
fi

echo -n "Please enter user's email address: "
read -e NEW_EMAIL

echo "Creating user account"
echo "useradd -c \"${NEW_NAME}\" -m  -G users \"${NEW_USER}\""
useradd -c "${NEW_NAME}" -m  -G users "${NEW_USER}"
echo "Please enter new users password (no characters are shown)"
echo "passwd ${NEW_USER}"
passwd "${NEW_USER}"

echo "Adding email address to send and forward settings"
echo "\"${NEW_USER}  ${NEW_EMAIL} \">> /etc/postfix/sender-canonical"
echo "${NEW_USER}  ${NEW_EMAIL}" >> /etc/postfix/sender-canonical
echo "\"${NEW_EMAIL}\" > /export/home/${NEW_USER}/.forward"
echo "${NEW_EMAIL}" > /export/home/${NEW_USER}/.forward
chown ${NEW_USER} /export/home/${NEW_USER}/.forward

# End Loop

echo "Syncing changed files"
rocks sync users
postmap /etc/postfix/sender-canonical
echo "Completed"

