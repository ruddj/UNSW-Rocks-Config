#%Module8.0#####################################################################

proc ModulesHelp { } {
        global helpmsg

        puts stderr "\t$helpmsg\n"
}


if { ! [ is-loaded gcc ] } {
  module load gcc
}

#if { ! [ is-loaded openmpi/1.5.4-gcc-4.6.3 ] } {
#  module load openmpi/1.5.4-gcc-4.6.3
#}


#
# 1. change 'version' string to appropriate version number: 6.0, 5.2, ...
#
set     version     2.0.x
set     project     OpenFOAM 
#
# 2. change 'mpihome' to base directory: /usr/mpi, /opt/mpi, ...
#
set	mpihome      /share/apps/opt/$project

set mpidir $mpihome/$project-$version


if [ file isdirectory $mpidir ] {
    module-whatis	"Changes the OpenFOAM home directory to $version"
    set helpmsg "Changes the OpenFOAM home directory to Version $version"
    # FOAM Settings
    setenv           WM_PROJECT     $project 
    setenv           WM_PROJECT_VERSION  $version
    setenv           FOAM_INST_DIR   $mpihome
    setenv           WM_PROJECT_INST_DIR $mpihome
    setenv           WM_PROJECT_DIR  $mpidir
    setenv           WM_THIRD_PARTY_DIR $mpihome/ThirdParty-$version
    setenv           WM_PROJECT_USER_DIR ~/$project
    setenv           WM_MPLIB OPENMPI
    setenv           MPI_BUFFER_SIZE 2000000000

    # System Settings
    prepend-path     PATH            $mpidir/bin
    prepend-path     LD_LIBRARY_PATH $mpidir/lib
    prepend-path     MANPATH         $mpidir/share/man  
    
} else {
    module-whatis	"OpenFOAM $version not installed"
    set helpmsg "OpenFOAM $version not installed"
    if [ expr [ module-info mode load ] || [ module-info mode display ] ] {
	# bring in new version
	puts stderr 	"OpenFOAM $version not installed on [uname nodename]"
    }
}