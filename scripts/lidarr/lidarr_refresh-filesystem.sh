#!/bin/bash
#
# Quick script to hit the Lidarr API and tell Lidarr to refresh the filesystem.
# This is useful when you add music to your library outside of Lidarr and need to update the database
# 
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################

LIDARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LIDARR_HOST="127.0.0.1"
LIDARR_PORT="8686"

DELAY_BETWEEN_REQUESTS="45" # Seconds to wait between API requests to Lidarr (so you don't over-load your system & API requests to Musicbrainz)

################################################################################################

jqInstalled() {
    if ! [ -x "$(command -v jq)" ]; then
        echo 'Please install the JQ tool to: [/usr/bin/jq], before running this script. Download JQ at: https://stedolan.github.io/jq/' >&2
        exit 1
    else
        JQ_BIN=`which jq`
    fi
}

base64Installed() {
    if ! [ -x "$(command -v base64)" ]; then
        echo 'Please install the base64 GNU Linux tool, before running this script.' >&2
        exit 1
    else
        BASE64_BIN=`which base64`
    fi
}

# Progress bar function
prog() {
    local w=50 p=$1;  shift
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /#};
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*";
}

jqInstalled && base64Installed

refreshArtistByID() {
    curl -s "http://$LIDARR_HOST:$LIDARR_PORT/api/v1/command" \
        -H "X-Api-Key: $LIDARR_API_KEY" \
        --data '{"name":"RefreshArtist","artistId":'"$1"'}' --compressed >> /dev/null

    sleep $DELAY_BETWEEN_REQUESTS
}

echo "Querying Lidarr API (this will take a while if you have 1000's of artists...."

ARTISTS_IN_LIBRARY=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $LIDARR_API_KEY" \
    -X GET http://$LIDARR_HOST:$LIDARR_PORT/api/v1/artist`

i=0
totalArtists=`echo $ARTISTS_IN_LIBRARY | jq '. | length'`

for artist in $(echo "${ARTISTS_IN_LIBRARY}" | jq -r '.[] | @base64'); do

    _jq() {
        echo ${artist} | eval $BASE64_BIN --decode | eval $JQ_BIN -r ${1}
    }
    i=$((i + 1))

    ARTIST_ID=`echo $(_jq '.id')`
    ARTIST_NAME=`echo $(_jq '.artistName')`
    
    # Simple progress bar so we know how far through the script we are (great for large collections)...
    taskpercent=$((i*100/totalArtists))
    prog "$taskpercent" $ARTIST_NAME...

    refreshArtistByID $ARTIST_ID

done

prog "$taskpercent" ""
echo -e "\n Finished."