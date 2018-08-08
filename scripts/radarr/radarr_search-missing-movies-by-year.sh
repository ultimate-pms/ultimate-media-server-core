#!/bin/bash
#
# I love my lists - but I don't like searching for movies older than year 2000 - Generally anything older than this I've already got :)
# This is a quick script to go and blow away any movies that have been added into Radarr each night (via a List) and remove them if they have not yet been downloaded...
# 
# Author: David Nedved
# https://github.com/david-nedved/ultimate-plex-setup/
#
################################################################################################

RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"

# Year (Movie released) to match against
SEARCH_YEAR="2018"

# Optional configuration - Suggest leave as default
RELEASE_STATUS="released" # This can one of: announced, inCinemas, released - Suggest leave as "released" to avoid fakes.
SLEEP_PERIOD=0.5 # Suggest 0.5, 1, 5, or 10 (depending on the speed of your internet) to avoid performing too many concurrent searches against your indexers...

################################################################################################

jqInstalled() {
    if ! [ -x "$(command -v jq)" ]; then
        echo 'Please install the JQ tool to: [/usr/bin/jq], before running this script. Download JQ at: https://stedolan.github.io/jq/' >&2
        exit 1
    fi
    JQ_BIN=`which jq`
}

# Progress bar function
prog() {
    local w=50 p=$1;  shift
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /#};
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*";
}

# Check JQ Installed first
jqInstalled

echo -e "++ Radarr Search Missing Movies by Year ++\n-----------------------------------------\n\n"
echo "Querying API for complete movie collection ..."

TOTALITEMS=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -X GET http://$RADARR_HOST:$RADARR_PORT/api/movie`

FILTERED_RESULTS=`echo $TOTALITEMS | jq '.[] | select(.year == '$SEARCH_YEAR') | select(.status == "'$RELEASE_STATUS'") | select(.downloaded == false)'`

i=0
total=`echo $FILTERED_RESULTS | jq '.title' | wc -l`

echo -e "\nTriggering Manual Search:"


for row in $(echo "$FILTERED_RESULTS" | jq -r '. | @base64'); do

    _jq() {
        echo ${row} | /usr/bin/base64 --decode | /usr/bin/jq -r ${1}
    }

    i=$((i + 1))

    MOVIENAME=`echo $(_jq '.title')`
    ID=`echo $(_jq '.id')`

    # Simple progress bar so we know how far through the script we are (great for large collections)...
    taskpercent=$((i*100/total))
    prog "$taskpercent" $MOVIENAME...

    # Fire off "search" against the individual movie
    curl -s -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $RADARR_API_KEY" \
        --data-binary '{"name":"moviesSearch","movieIds":['$ID']}' \
        http://$RADARR_HOST:$RADARR_PORT/api/command >> /dev/null

    sleep $SLEEP_PERIOD 

done

prog "$taskpercent" ""
echo -e "\n Finished."