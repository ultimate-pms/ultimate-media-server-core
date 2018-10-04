#!/bin/bash
#
# Quick and nasty script to hit the Last.fm API and add similar artists from your top artists on the last month to Lidarr.
# Suggest you start with some realistic (low) values when adding for the first time so you don't get banned by Last.FM and your Trackers...
#
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################

LASTFM_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Sign up for a free last.fm account and make an API Key at: https://www.last.fm/api/account/create
LASTFM_USER="xxxxxxxxxx" # YOUR LASTFM USERNAME
LIDARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LIDARR_HOST="127.0.0.1"
LIDARR_PORT="8686"

MUSIC_DIRECTORY="/music/" # Path to artist/save/location directory...

SIM_LIMIT=20 # MAX NUMBER OF SIMILAR ARTISTS BY ARTISTS TO GET
MONTH_LIMIT=100

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

LASTFM_ARTISTS=`curl -s -H "Accept: application/json" \
        -X GET "http://ws.audioscrobbler.com/2.0/?method=user.getTopArtists&user=$LASTFM_USER&period=1month&api_key=$LASTFM_KEY&format=json&limit=$MONTH_LIMIT"`

for artist in $(echo "${LASTFM_ARTISTS}" | jq -r '.topartists.artist[] | @base64'); do

        _jq() {
            echo ${artist} | /usr/bin/base64 --decode | eval $JQ_BIN -r ${1}
        }

    ARTIST_NAME=`echo $(_jq '.name')`

    echo "Getting Similar from : $ARTIST_NAME"

    LASTFM_ARTISTS_SIMILAR=`curl -s -H "Accept: application/json" \
        -X GET "http://ws.audioscrobbler.com/2.0/?method=artist.getSimilar&autocorrect=1&artist=$(rawurlencode "$ARTIST_NAME")&api_key=$LASTFM_KEY&format=json&limit=$SIM_LIMIT"`

    for sim_artist in $(echo "${LASTFM_ARTISTS_SIMILAR}" | jq -r '.similarartists.artist[] | @base64'); do

        _jq() {
            echo ${sim_artist} | /usr/bin/base64 --decode | eval $JQ_BIN -r ${1}
        }

        SIM_ARTIST_NAME=`echo $(_jq '.name')`

#       echo "SIMILAR : $SIM_ARTIST_NAME"

        SIM_ARTIST_RESPONSE=`lidarr_SearchArtist "$SIM_ARTIST_NAME"` #"$SIM_ARTIST_NAME"`

        if [ "$SIM_ARTIST_RESPONSE" == "0" ]; then
            echo "No results found in Lidarr for: [$SIM_ARTIST_NAME]"
        else

            IS_ADDED=`echo $SIM_ARTIST_RESPONSE | jq '. | first | .monitored'`

            # Only fire request to add artist if not yet in library...
            if [ "$IS_ADDED" == "false" ]; then

                echo "Adding: [$SIM_ARTIST_NAME]..."
                # Sometimes there may be multiple artists - generally the first artist is the one we want...
                ARTIST_ITEM=`echo $SIM_ARTIST_RESPONSE | jq '. | first'`

                QUALITY_OPTIONS=`echo $ARTIST_ITEM | jq -c '.qualityProfileId=1|.languageProfileId=1|.metadataProfileId=1|.albumFolder=true|.monitored=true'`
                ADD_OPTIONS=`echo $QUALITY_OPTIONS | jq -c ".addOptions = {selectedOption:0,monitored:true,searchForMissingAlbums:true} | .rootFolderPath = \"$MUSIC_DIRECTORY\""`

                lidarr_addArtist "$ADD_OPTIONS"
                sleep 3
#            else
#              echo "Artist SIMILAR : $SIM_ARTIST_NAME - Already Exists"
            fi
        fi

    done
done
