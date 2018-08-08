#!/bin/bash
#
# Quick script to hit the Lidarr API and search for any tracks that are missing (and on your wanted list) in Lidarr...
# Suggest running this script on a cron each night.
# 
# Author: David Nedved
# https://github.com/david-nedved/ultimate-plex-setup/
#
################################################################################################

LIDARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LIDARR_HOST="127.0.0.1"
LIDARR_PORT="8686"

BATCH_SIZE=10 # How many albums do we want to search for at once (suggest 10 - 20) - Don't make this too high or you'll probably get banned on your indexer...
SLEEP_TIME=30 # How long to pause between each "batched" group of searches (don't make this too low or you'll fire off too many searches to your indexers at once and get banned)

################################################################################################

jqInstalled() {
    if ! [ -x "$(command -v jq)" ]; then
        echo 'Please install the JQ tool to: [/usr/bin/jq], before running this script. Download JQ at: https://stedolan.github.io/jq/' >&2
        exit 1
    else
        JQ_BIN=`which jq`
    fi
}

# Progress bar function
prog() {
    local w=50 p=$1;  shift
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /#};
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*";
}

# Check JQ Installed first..
jqInstalled

echo -e "++ Lidarr Music Search Trigger(er) ++\n------------------------------\n\n"
echo "Querying API for missing tracks - please be patient..."

getTracks() {

    if [ -z "$1" ]; then
        PAGE=1
    else
        PAGE=$1
    fi

    PAGE_MISSING=`curl -s -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $LIDARR_API_KEY" \
        -X GET http://$LIDARR_HOST:$LIDARR_PORT/api/v1/wanted/missing?page=$PAGE&pageSize=$BATCH_SIZE&sortDirection=descending&sortKey=releaseDate&monitored=true`

    echo $PAGE_MISSING
}

i=0
current_page=1
finished=false
PAGE_RESULTS=`getTracks $current_page`
total=`echo $PAGE_RESULTS | jq '.totalRecords'`

echo -e "\nProcessing results:"

itiratePage() {
    SEARCH_IDS=()
    for row in $(echo "${PAGE_RESULTS}" | jq -r '.records[] | @base64'); do

        _jq() {
            echo ${row} | /usr/bin/base64 --decode | eval $JQ_BIN -r ${1}
        }
        i=$((i + 1))

        ALBUMID=`echo $(_jq '.id')`
        TITLE=`echo $(_jq '.title')`
        
        # Simple progress bar so we know how far through the script we are (great for large collections)...
        taskpercent=$((i*100/total))
        prog "$taskpercent" $TITLE...
        SEARCH_IDS+=($ALBUMID)
    done

    ALBUM_IDS=`printf "%s," "${SEARCH_IDS[@]}" | cut -d "," -f 1-${#SEARCH_IDS[@]}`

    # Fire off request to search the first page of results...
    curl -s "http://$LIDARR_HOST:$LIDARR_PORT/api/v1/command" \
          -H "X-Api-Key: $LIDARR_API_KEY" \
          --data "{\"name\":\"AlbumSearch\",\"albumIds\":[$ALBUM_IDS]}" >> /dev/null

    if [ "$i" == "$total" ]; then
        finished=true
    fi

    sleep $SLEEP_TIME
}

while [ "$finished" != "true" ]; do
   current_page=$((current_page + 1))
   PAGE_RESULTS=`getTracks $current_page`

   itiratePage
done

prog "$taskpercent" ""
echo -e "\n Finished."
