#!/bin/bash

# This is a simple script using AtomicParsley to check MP4 files for embedded
# filenames and remove them if they are found, so Plex displays pretty / "clean" file names :)
# 
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#

atomicParsleyInstalled() {
    if ! [ -x "$(command -v AtomicParsley)" ]; then
        echo 'Please install AtomicParsley to use this script - http://atomicparsley.sourceforge.net/' >&2
        exit 1
    fi
}

function processFile {

    SOURCE_FILE="$1"
    HAS_EMBEDDED_TITLE=`AtomicParsley "$SOURCE_FILE" --textdata | grep -i -c 'Atom "©cmt" contains:'`

    if [ "$HAS_EMBEDDED_TITLE" -eq "1" ]; then
        ## Dirty embedded filenames found - remove them...
        echo "Cleaning up: [$fileName]"
        AtomicParsley "$fileName" --title "" --overWrite
        exitCode=$?

        exit $exitCode
    else
        exit 0
    fi

}

atomicParsleyInstalled
processFile "$1"
