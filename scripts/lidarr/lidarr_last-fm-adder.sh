#!/bin/bash
#
# Quick and nasty script to hit the Last.fm API and add in the top artists (by genre) to Lidarr.
# Suggest you start with some realistic (low) values when adding for the first time so you don't get banned by Last.FM and your Trackers...
# 
# Author: David Nedved
# https://github.com/david-nedved/ultimate-plex-setup/
#
################################################################################################

LASTFM_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Sign up for a free last.fm account and make an API Key at: https://www.last.fm/api/account/create

LIDARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LIDARR_HOST="127.0.0.1"
LIDARR_PORT="8686"

MUSIC_DIRECTORY="/nas/Music/" # Path to artist/save/location directory...
PAUSE_BETWEEN_ARTISTS=30 # Time in seconds to wait between adding artists (if you don't set this to a sensible number you may get banned from your indexer(s) when running this for the first time...)

# Complete array like so "Genre:NumberOfItems" (i.e. "house:100" would pull in the current top 100 house music artists)... 
# You can get the top genres by running: curl "http://ws.audioscrobbler.com/2.0/?method=tag.getTopTags&tag=house&api_key=$LASTFM_KEY&format=json"

GENRES_TO_ADD=(
    'electronic:10'
    'dance:10'
    'house:10'
    'trance:10'
    'experimental:10'
    'ambient:10'
    'rock:10'
    'alternative:10'
    'indie:10'
    'pop:10'
    'metal:10'
    'jazz:10'
    'punk:10'
    'Hip-Hop:10'
    'instrumental:10'
    'chillout:10'
    'electronica:10'
    'Classical:10'
    'industrial:10'
    'blues:10'
    'rap:10'
    'acoustic:10'
    'psychedelic:10'
    '90s:10'
)

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

# Search LastFM for trending Artists (based on genres and limits specified above)
for genre in "${GENRES_TO_ADD[@]}"; do :

    SEARCH_TERM=`echo "$genre" | cut -d ":" -f 1`
    SEARCH_LIMIT=`echo "$genre" | cut -d ":" -f 2`

    LASTFM_ARTISTS=`curl -s -H "Accept: application/json" \
        -X GET "http://ws.audioscrobbler.com/2.0/?method=tag.gettopartists&tag=$(rawurlencode "$SEARCH_TERM")&api_key=$LASTFM_KEY&format=json&limit=$SEARCH_LIMIT"`

    for artist in $(echo "${LASTFM_ARTISTS}" | jq -r '.topartists.artist[] | @base64'); do

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

                lidarr_addArtist "$ADD_OPTIONS"
                sleep 3
            fi
        fi

    done
done
