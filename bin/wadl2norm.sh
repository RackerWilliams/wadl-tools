#! /bin/bash

# Wrapper script for wadl normalization xslts.
#
# Author: david.cramer@rackspace.com
# Copyright 2011 Rackspace Hosting.

function saxonize {
    java \
	-jar "$(dirname $0)/../lib/saxon-9.1.0.8.jar" \
        -s:"$1" \
	-xsl:"$(dirname $0)/../xsl/$2" \
	-strip:all \
	-o:"$3"
}

if [ -f "$1" ]
then 
    saxonize $1 normalizeWadl.xsl /tmp/wadl2norm1.xml
    saxonize /tmp/wadl2norm1.xml normalizeWadl2.xsl /tmp/wadl2norm2.xml
    saxonize /tmp/wadl2norm2.xml normalizeWadl3.xsl ${1%%.wadl}-normalized.wadl "format"="$2format"

    # Clean up temp files:
    rm /tmp/wadl2norm1.xml /tmp/wadl2norm2.xml
else 
    echo ""
    echo "Usage: $(basename $0) wadl-file <url|xml>"
    echo "       url: TODO, explain, say which is default"
    echo "       xml: TODO, explain"
    exit 1
fi