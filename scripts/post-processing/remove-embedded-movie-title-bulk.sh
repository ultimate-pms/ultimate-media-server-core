#!/bin/bash
#
# An easy way to find all existing videos that have been downloaded and run them through any post processing scripts
# This is intended to be run just once when setting up your scripts etc...
# 
# Author: David Nedved
# https://github.com/david-nedved/ultimate-plex-setup/
#
################################################################################################

# Adjust as needed.
SEARCH_LOCATION='/nas/*'
LOG_FILE="pp-status.txt"
MIN_SIZE=30M
FILE_EXTENSIONS=(
    "mp4"
    "m4a"
    "avi"
    "m4v"
    "mpg"
    "mpeg"
    "wmv"
    "mkv"
)

# No need to edit below here.
################################################################################################

# Progress bar function
prog() {
    local w=50 p=$1;  shift
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /#};
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*";
}

NAME_ARGS=""
for i in "${FILE_EXTENSIONS[@]}"; do :
    if [[ -z "${NAME_ARGS// }" ]]; then
        NAME_ARGS="$i"
    else
        NAME_ARGS="$NAME_ARGS|$i"
    fi
done

echo -e "++ Bulk Processing ++\n--------------------------------\n"
echo "Building file list - please be patient..."


SEARCH_COMMAND="find $SEARCH_LOCATION -type f -size +$MIN_SIZE -regextype posix-egrep -regex \".*\\.($NAME_ARGS)\$\" -print0"

process_movies=()
while IFS=  read -r -d $'\0'; do
    process_movies+=("$REPLY")
done < <(eval $SEARCH_COMMAND | sort -z )

count=0
total=`echo ${#process_movies[@]}`
echo -e "\nProcessing results:"

RED='\033[0;31m'
NC='\033[0m' # No Color

if [ "$total" -gt "100" ]; then
    SLOW_COMMENT="(this will take a while)"
fi
echo "Converting $total files $SLOW_COMMENT..."

for filename in "${process_movies[@]}"; do :

    count=$((count + 1))
    taskpercent=$((count*100/total))
    shortName="${filename##*/}"

    prog "$taskpercent" $shortName...
    # ./fake-video --silent --log --video="$filename" 
    ./remove-embedded-movie-title.sh "$filename"
    exitCode=$?

    if [ $exitCode -eq 0 ]; then

        prog "$taskpercent" ""

        if [ ! -z "$LOG_FILE" ]; then
            echo -e "OK:\t[$filename]" >> $LOG_FILE
        fi
    else
        if [ ! -z "$LOG_FILE" ]; then
            echo -e "ERROR:\t[$filename]" >> $LOG_FILE
        fi
    fi

done

echo ""
