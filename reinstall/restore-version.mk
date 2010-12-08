ROLLNAME	= $(shell uname -n)-restore
NAME		= roll-$(shell uname -n)-restore
VERSION		= $(shell date +%Y.%m.%d)
RELEASE		= 0
COLOR   	= orchid

REDHAT.ROOT 	= $(PWD)

CONTRIB_PKG_VER	= $(shell /opt/rocks/bin/rocks report version)
CONTRIB_PKG_DIR	= $(shell /opt/rocks/bin/rocks report distro)/contrib

#
# these are the files that will be restored when this roll is supplied
# during installation
#
FILES	+= /etc/X11/xorg.conf /etc/hosts.local \
	/export/site-roll/rocks/src/roll/restore/version.mk \
	/etc/postfix/main.cf /etc/postfix/recipient-canonical /etc/postfix/sender-canonical \
	/etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key.pub /etc/ssh/ssh_host_key \
	/etc/ssh/ssh_host_key.pub /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub \
	/export/home/install/contrib

FILES	+= /etc/X11/xorg.conf $(wildcard /var/named/*local)
FILES	+= $(wildcard /etc/ssh/*key*)	
	
SCRIPTS	+=
