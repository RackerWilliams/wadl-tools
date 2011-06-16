#! /bin/bash

# Wrapper script for wadl normalization xslts.
#
# Author: david.cramer@rackspace.com
# Copyright 2011 Rackspace Hosting.

# This function figures out the location of the original script (as opposed to any chain of 
# symlinks pointing to it). Source: 
# http://muffinresearch.co.uk/archives/2008/10/10/bash-resolving-symlinks-to-shellscripts/
function resolve_symlink {
    SCRIPT=$1 NEWSCRIPT=''
    until [ "$SCRIPT" = "$NEWSCRIPT" ]; do
        if [ "${SCRIPT:0:1}" = '.' ]; then SCRIPT=$PWD/$SCRIPT; fi
        cd $(dirname $SCRIPT)
        if [ ! "${SCRIPT:0:1}" = '.' ]; then SCRIPT=$(basename $SCRIPT); fi
        SCRIPT=${NEWSCRIPT:=$SCRIPT}
        NEWSCRIPT=$(ls -l $SCRIPT | awk '{ print $NF }')
    done
    if [ ! "${SCRIPT:0:1}" = '/' ]; then SCRIPT=$PWD/$SCRIPT; fi
    echo $(dirname $SCRIPT)
}
DIR=$(resolve_symlink $0)

function saxonize {
    java \
	-jar "$DIR/../lib/saxon-9.1.0.8.jar" \
        -s:"$1" \
	-xsl:"$DIR/../xsl/$2" \
	-strip:all \
	-o:"$3" \
	format="$4-format"
}

if [[ -f "$1" && ( ! -n $2 || $2 = "path" || $2 = "tree") ]]
then 
    saxonize $1 normalizeWadl.xsl /tmp/wadl2norm1.xml
    saxonize /tmp/wadl2norm1.xml normalizeWadl2.xsl /tmp/wadl2norm2.xml
    saxonize /tmp/wadl2norm2.xml normalizeWadl3.xsl ${1%%.wadl}-normalized.wadl $2

    # Clean up temp files:
    # rm /tmp/wadl2norm1.xml /tmp/wadl2norm2.xml
else 
    echo ""
    echo "Usage: $(basename $0) wadl-file <path|tree>"
    echo "       path: TODO, explain, say which is default"
    echo "       tree: TODO, explain"
    exit 1
fi