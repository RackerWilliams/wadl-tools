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
    rm -f /tmp/normalized/xsd-*.xsd
    rm -f /tmp/wadl2norm?.wadl
    rm -f "$(dirname $1)/normalized/*"

    xmllint --noent --noout --schema "$DIR/../xsd/wadl.xsd"  $1
    [ $? -eq 0 ] || exit 1

    saxonize $1 normalizeWadl.xsl /tmp/wadl2norm1.wadl
    xmllint --noout --schema "$DIR/../xsd/wadl.xsd"  /tmp/wadl2norm1.wadl 
    [ $? -eq 0 ] || exit 1
    xmllint --noout --schema "$DIR/../xsd/XMLSchema11.xsd"  /tmp/normalized/xsd-*.xsd 

    saxonize /tmp/wadl2norm1.wadl normalizeWadl2.xsl /tmp/wadl2norm2.wadl
    xmllint --noout --schema "$DIR/../xsd/wadl.xsd"  /tmp/wadl2norm2.wadl 
    [ $? -eq 0 ] || exit 1

    saxonize /tmp/wadl2norm2.wadl normalizeWadl3.xsl  /tmp/wadl2norm3.wadl $2
    xmllint --noout --schema "$DIR/../xsd/wadl.xsd"  /tmp/wadl2norm3.wadl
    [ $? -eq 0 ] || exit 1

    cp /tmp/wadl2norm3.wadl $(dirname $1)/normalized/$(basename ${1%%.wadl}.wadl)

    # Clean up temp files:
    # rm /tmp/wadl2norm1.wadl /tmp/wadl2norm2.wadl
    # cp -r $(dirname $1)/xsd $(dirname $1)/normalized
    # cp -r /tmp/wadl2norm?.wadl  $(dirname $1)/normalized 
    cp -r /tmp/normalized/*.xsd $(dirname $1)/normalized

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