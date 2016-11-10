#!/bin/bash
#

# Experiment number needed
if [ $# -ne 3 ] ; then
   echo " $(basename $0) needs synoptic forcing option, start time and end time"
   echo ""
   echo "Example:"
   echo "    $(basename $0) erai 2013-01-01T00:00:00  2013-01-05T00:00:00 "
   echo "Generates forcing from erai over the time span"
   exit
fi
export forcing=$1
export start=$2
export stop=$3

# Set basedir based on relative paths of script
# Can be troublesome, but should be less prone to errors
# than setting basedir directly
# --- S is scratch directory,
# --- D is permanent directory,
# Must be in expt dir to run this script
if [ -f EXPT.src ] ; then
   export BASEDIR=$(cd .. && pwd)
else
   echo "Could not find EXPT.src. This script must be run in expt dir"
   exit 1
fi
export BINDIR=$(cd $(dirname $0) && pwd)/
source ${BINDIR}/common_functions.sh || { echo "Could not source ${BINDIR}/common_functions.sh" ; exit 1 ; }
source ${BASEDIR}/REGION.src || { echo "Could not source ${BASEDIR}/REGION.src" ; exit 1 ; }
source ./EXPT.src || { echo "Could not source ./EXPT.src" ; exit 1 ; }
D=$BASEDIR/force/synoptic/$E/
S=$D/SCRATCH
[ ! -d $D ] && mkdir -p $D
[ ! -d $S ] && mkdir -p $S
cd       $S || { echo " Could not descend scratch dir $S" ; exit 1;}


#
# --- Sanity check on forcing option
#
if [ ${forcing:0:4} == "erai" ] ; then
   xmlfile=$BASEDIR/../input/era-interim.xml
else 
   tellerror "Forcing option is erai only..."
   exit 1
fi


#
# --- Input. Function in common_functions.sh
#
copy_setup_files $S





cmd="$BASEDIR/../python/hycom_atmfor.py $start $stop $xmlfile $forcing"
eval $cmd   ||  { echo "Error running $cmd " ; exit 1 ; }

# The nersc era40 forcing is region-independent 
for i in forcing.*.[ab] ; do
   new=$(echo $i | sed "s/^forcing\.//")
   mv $i $D/$new
   echo "Created  $D/$new"
done




