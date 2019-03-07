#!/bin/bash
#
# Quick and nasty script to hit the Deezer API and add in your fav artists to Lidarr.
# Suggest you start with some realistic (low) values when adding for the first time so you don't get banned by Last.FM and your Trackers...
#
# Author: foulou
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################

DEEZER_USER_ID="XXXXXXXX"
# https://www.deezer.com/
# then go to your playlist or your albums etc...
# to get you user_id, look in the URL : https://www.deezer.com/fr/profile/XXXXXX/playlists
# the XXXXX is your user_id

DEEZER_ARTISTS_LIMIT="-1" #  other value to limit to X artists, but we need everything

LIDARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LIDARR_HOST="localhost"
LIDARR_PORT="8686"

MUSIC_DIRECTORY="/music/" # Path to artist/save/location directory...

################################################################################################

jqInstalled() {
    if ! [ -x "$(command -v jq)" ]; then
        echo 'Please install the JQ tool to: [/usr/bin/jq], before running this script. Download JQ at: https://stedolan.github.io/jq/' >&2
        exit 1
    else
        JQ_BIN=`which jq`
    fi
}

rawurlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"    # You can either set a return variable (FASTER)
    REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

lidarr_SearchArtist() {
    if [ -z "$1" ]; then
        echo "0"
    else
        ARTIST=$1
        SEARCH_RESPONSE=`curl -s -H "X-Api-Key: $LIDARR_API_KEY" "http://$LIDARR_HOST:$LIDARR_PORT/api/v1/artist/lookup?term=$(rawurlencode "$ARTIST")"`

        if [ "$SEARCH_RESPONSE" == "[]" ]; then
            echo "0"
        else
            echo $SEARCH_RESPONSE
        fi
    fi
}

lidarr_addArtist() {
    if [ -z "$1" ]; then
        echo "0"
    else
        POST_DATA=$1

        curl -s "http://$LIDARR_HOST:$LIDARR_PORT/api/v1/artist" \
            -H "X-Api-Key: $LIDARR_API_KEY" \
            --data-binary "$POST_DATA" >> /dev/null

    fi
}


jqInstalled

# Search Deezer for Artists

DEEZER_ARTISTS=`curl -s -H "Accept: application/json" \
        -X GET "https://api.deezer.com/user/$DEEZER_USER_ID/artists?limit=$DEEZER_ARTISTS_LIMIT"`

for artist in $(echo "${DEEZER_ARTISTS}" | jq -r '.data[] | @base64'); do

        _jq() {
            echo ${artist} | /usr/bin/base64 --decode | eval $JQ_BIN -r ${1}
        }

    ARTIST_NAME=`echo $(_jq '.name')`
       
    ARTIST_RESPONSE=`lidarr_SearchArtist "$ARTIST_NAME"` #"$ARTIST_NAME"`

        if [ "$ARTIST_RESPONSE" == "0" ]; then
            echo "No results found in Lidarr for: [$ARTIST_NAME]"
        else

            IS_ADDED=`echo $ARTIST_RESPONSE | jq '. | first | .monitored'`

            # Only fire request to add artist if not yet in library...
            if [ "$IS_ADDED" == "false" ]; then

                echo "Adding: [$ARTIST_NAME]..."
                # Sometimes there may be multiple artists - generally the first artist is the one we want...
                ARTIST_ITEM=`echo $ARTIST_RESPONSE | jq '. | first'`

                QUALITY_OPTIONS=`echo $ARTIST_ITEM | jq -c '.qualityProfileId=1|.languageProfileId=1|.metadataProfileId=1|.albumFolder=true|.monitored=true'`
                ADD_OPTIONS=`echo $QUALITY_OPTIONS | jq -c ".addOptions = {selectedOption:0,monitored:true,searchForMissingAlbums:true} | .rootFolderPath = \"$MUSIC_DIRECTORY\""`

                #lidarr_addArtist "$ADD_OPTIONS"
                sleep 3
            else
                echo "Artist [$ARTIST_NAME] - Already Exists"
            fi
        fi

done
