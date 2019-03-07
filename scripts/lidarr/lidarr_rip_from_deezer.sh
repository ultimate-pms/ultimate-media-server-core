#!/bin/bash
#
# A script to query missing albums from Lidarr and try to source (rip) them from Deezer
# 
#
################################################################################################

LIDARR_API_KEY="40af694abcea4762821a2fbefcb4d934"
LIDARR_HOST="10.16.10.5"
LIDARR_PORT="8686"


#MUSIC_DIR="/Volumes/bay-1/Music"
MUSIC_DIR="/nas/bay-1/Music"
DOWNLOAD_DIR="/nas/bay-1/Music/Music_IMPORT/__8/"

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

# Progress bar function
prog() {
    local w=50 p=$1;  shift
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /#};
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*";
}

existsOnDisk() {

    UPPER_ARTIST=`echo "$1" | awk '{print toupper($0)}'`
    ARTIST_PWD="$MUSIC_DIR/$UPPER_ARTIST"
    ALBUM=`echo "$2" | awk '{print toupper($0)}'`

    LWR_MATCH_ARTIST=`echo "$1" | awk '{print tolower($0)}'`
    LWR_MATCH_ALBUM=`echo "$2" | awk '{print tolower($0)}'`

    if [ -d "$ARTIST_PWD" ]; then
        
        # Artist directory exists, what about album? - NB Pushing into array, because we want to strip (YYYY) from folder names if it exists
        artist_albums_on_disk=()
        while IFS=  read -r -d $'\0'; do
            artist_albums_on_disk+=("$REPLY")
        done < <(find "$ARTIST_PWD" -maxdepth 1 ! -path "$ARTIST_PWD" -type d -print0)

        for i in "${artist_albums_on_disk[@]}"; do

            # Make sure that we match against existing folders in filesystem all lowercase (case insensitive)
            LWR_ALBUM=`echo "$i" | awk '{print tolower($0)}'`

            if [[ "$LWR_ALBUM" == *"$LWR_MATCH_ALBUM"* ]]; then
                # Album appears to alerady exist, skip downloading
                return 0
            fi
        done

        # Album does not yet appear to exist, download!
        return 1

    else
        # Artist dir does not yet exist (let alone album), download!
        return 1
    fi

}

ripAlbum() {

    mkdir -p "$DOWNLOAD_DIR"
    (cd /opt/docker-deezerripper/app ; ./SMLoadr-linux-x64 --path "$DOWNLOAD_DIR" --url "$1")

    docker exec -i beets bash -c \
        "export BEETSDIR='/config/' && beet -v -l /config/musiclibrary.blb -c /config/skeleton/skeleton-config.yaml import -A -q -i -l /config/import.log $DOWNLOAD_DIR"

    rm -rf "$DOWNLOAD_DIR"
}

getDeezerAlbum() {

    SEARCH=`curl -s "https://api.deezer.com/search?q=artist:%22$(rawurlencode "$1")%22%20album:%22$(rawurlencode "$2")%22&order=RANKING&version=js-v1.0.0"`

    # Deezer API returns craploads of items, only filter out the keys that we care about and ensure that we only process "unique" items (so we don't download the album twice)
    FILTERED_RESULTS=`echo $SEARCH | jq '.data[] | {album,artist} | (.album.id|tostring) + "|" + (.artist.name) + "|" + (.album.title)' --raw-output | sort -u`
    taskpercent="$3"

    # Deezer search is not the best so we need to do some parsing in bash to ensure that we're only ripping the album we requested and not other artists...
    while read -r result; do

        IFS='|' read -ra RESULT <<< "$result"

        # Make sure that we match against strings in lowercase (Some responses capatalise items (The should be the, etc...))
        LWR_RETURNED_ARTIST=`echo "${RESULT[1]}" | awk '{print tolower($0)}'`
        LWR_RETURNED_ALBUM=`echo "${RESULT[2]}" | awk '{print tolower($0)}'`

        LWR_MATCH_ARTIST=`echo "$1" | awk '{print tolower($0)}'`
        LWR_MATCH_ALBUM=`echo "$2" | awk '{print tolower($0)}'`

        # If artist matches
        if [[ "$LWR_RETURNED_ARTIST" == "$LWR_MATCH_ARTIST" ]]; then
            # If album matches
            if [[ "$LWR_RETURNED_ALBUM" == "$LWR_MATCH_ALBUM" ]]; then
                
                # Has it already been downloaded and files saved on disk?
                downloadTrack=$(existsOnDisk "$1" "$2")
                DOWNLOAD=$?

                if [ "$DOWNLOAD" -eq 1  ]; then
                    prog "$taskpercent" "$1 / $2 ..."

                    ALBUM_URL="https://www.deezer.com/en/album/${RESULT[0]}"
                    ripAlbum "$ALBUM_URL"

                else
                    prog "$taskpercent" "$1 / $2 ..."
                fi

            fi
        fi

    done <<< "$FILTERED_RESULTS"
}

getAlbums() {

    ALBUMS=`curl -s -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $LIDARR_API_KEY" \
        -X GET http://$LIDARR_HOST:$LIDARR_PORT/api/v1/album?artistId=$1`

    #ALBUMS=`cat test2.json`

    for album in $(echo "${ALBUMS}" | jq -r '.[] | @base64'); do

        _jq() {
            echo ${album} | eval $BASE64_BIN --decode | eval $JQ_BIN -r ${1}
        }
        i=$((i + 1))

        ALBUM_TITLE=`echo $(_jq '.title')`
        ARTIST_NAME="$2"

        getDeezerAlbum "$ARTIST_NAME" "$ALBUM_TITLE" "$3"

    done
}

jqInstalled && base64Installed

echo "Querying Lidarr API (this will take a while if you have 1000's of artists...."

# ARTISTS_IN_LIBRARY=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $LIDARR_API_KEY" \
    -X GET http://$LIDARR_HOST:$LIDARR_PORT/api/v1/artist`

ARTISTS_IN_LIBRARY=`cat /tmp/lidar.artists`

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

    getAlbums "$ARTIST_ID" "$ARTIST_NAME" "$taskpercent"

done

prog "$taskpercent" ""
echo -e "\n Finished."