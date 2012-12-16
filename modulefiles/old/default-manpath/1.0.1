#%Module -*- tcl -*-
#
# This modulefile exists because of the way "man" gets its path.
# if $MANPATH is set, it ignored /etc/man.config, which is where all
# the default man paths are set.  There's an undocumented feature of
# man in that if you have ":" at the beginning or end (or, more specifically,
# any path in $MANPATH is empty), it'll read the MANPATH entries from
# /etc/man.config.  However, the modules commands "append-path" and 
# "prepend-path" are too smart -- they won't let us append or prepend
# an empty path.  
#
# So the solution we devised is to have a new modulefile that reads
# in the MANPATH entries from /etc/man.config and add them here
# with append-path.  Then, if the user doesn't want them, they can
# just unload this module.
#

proc ModulesHelp { } {
  puts stderr "\tThis module adds in the default MANPATH entries"
  puts stderr "\tto the $MANPATH environment variable from /etc/man.config."
}

module-whatis   "Add default entries to the MANPATH environment variable"

# Read in /etc/man.config, find all MANPATH entires

if { [file exists /etc/man.config] } {
  set manconfig [open "|egrep ^MANPATH /etc/man.config" "r"]
  while { [eof $manconfig] == 0 } {
    gets $manconfig line
    set words [split $line]

    # To be blunt, I didn't have the time or inclination to figure out the
    # right TCL syntax to get the regexp right, above -- all I got was
    # "starting the line with MANPATH", but there's still a few items
    # in /etc/man.config that can start with MANPATH, but not *be* MANPATH
    # (e.g., "MANPATH_MAP").  So just double check here that we got
    # MANPATH, and not anything else.

    if { [lindex $words 0] == "MANPATH" } {
      append-path MANPATH [lindex $words 1]
    }
  }
  close $manconfig
}
