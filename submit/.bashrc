# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

# sets up G03 run environment.
g03root="/gaussian"

GAUSS_SCRDIR="/state/partition2"
export g03root GAUSS_SCRDIR
if [ -f $g03root/g03/bsd/g03.profile ]; then
	. $g03root/g03/bsd/g03.profile
fi

if [ -f $g03root/gv/init_gv.bash ]; then
	. $g03root/gv/init_gv.bash
fi

#SGE
. /opt/gridengine/default/common/settings.sh

#echo Loaded Gauss Config

alias exp='/usr/bin/nautilus --no-desktop --browser'
