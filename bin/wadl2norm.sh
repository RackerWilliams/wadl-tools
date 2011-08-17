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

# If they passed in a file to process and if the optional
# second argument is "path" or "tree", then 
# "do the needful". Otherwise, quit with a usage statement.
if [[ -f "$1" && ( ! -n $2 || $2 = "path" || $2 = "tree") ]]
then 
    [ -d "$(dirname $1)/normalized" ] || mkdir $(dirname $1)/normalized

    # Cleanup output of the last run
    #rm -f "$(dirname $1)/normalized/*"

    # Validate hte input wadl file against the wadl xsd.
    xmllint --noent --noout --schema "$DIR/../xsd/wadl.xsd"  $1
    [ $? -eq 0 ] || exit 1

    # Process the document wadl document.
    saxonize $1 normalizeWadl.xsl $(dirname $1)/normalized/$(basename ${1%%.wadl}.wadl) $2
    
    # Validate the output wadl.
    xmllint --noout --schema "$DIR/../xsd/wadl.xsd"  $(dirname $1)/normalized/$(basename ${1%%.wadl}.wadl)
    #[ $? -eq 0 ] || exit 1
    # Validate the generated xsds
    xmllint --noout --schema "$DIR/../xsd/XMLSchema11.xsd"  $(dirname $1)/normalized/$(basename ${1%%.wadl}-xsd-*.xsd)
    #[ $? -eq 0 ] || exit 1

else 

    echo ""
    echo "Usage: $(basename $0) wadl-file <path|tree>"
    echo "       path: Format resources in path format, "
    echo "             e.g. <resource path='foo/bar'/>"
    echo "       tree: Format resources in tree format, "
    echo "             e.g. <resoruce path='foo'><resource path='bar'>..."
    echo "       If you omit the last parameter, the script makes no "
    echo "       changes to the structure of the resources."
    exit 1
fi