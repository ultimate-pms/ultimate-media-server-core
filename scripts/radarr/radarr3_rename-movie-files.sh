#!/bin/bash
#
# Quick and dirty script to hit the Radarr API and rename any movies (via the Radar API) so that they are correctly indexed in Plex :)
#
# Example:
#           Source: "xmen.the.last.stand.2006.team-xxx.mkv"
#           Becomes: "X-Men The Last Stand (2006) HDTV-720p.mkv"
# 
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################

RADARR_API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXX"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"
EXCLUE_FILENAMES_CONTAINING="NoDTS"

################################################################################################

jqInstalled() {
    if ! [ -x "$(command -v jq)" ]; then
        echo 'Please install the JQ tool to: [/usr/bin/jq], before running this script. Download JQ at: https://stedolan.github.io/jq/' >&2
        exit 1
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

echo -e "++ Radarr Movie File Renamer ++\n------------------------------\n\n"
echo "Querying API for complete movie collection - please be patient..."

TOTALITEMS=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -X GET http://$RADARR_HOST:$RADARR_PORT/api/movie`

i=0
total=`echo $TOTALITEMS | jq '. | length'`
echo -e "\nProcessing results:"

for row in $(echo "${TOTALITEMS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | /usr/bin/base64 --decode | /usr/bin/jq -r ${1}
    }
    i=$((i + 1))

    MOVIENAME=`echo $(_jq '.title')`
    DOWNLOADED=`echo $(_jq '.downloaded')`
    ID=`echo $(_jq '.id')`
    FILENAME=`echo $(_jq '.movieFile.relativePath')`

    # Simple progress bar so we know how far through the script we are (great for large collections)...
    taskpercent=$((i*100/total))
    prog "$taskpercent" $MOVIENAME...

    if [ "$DOWNLOADED" == "true" ]; then

        if [[ $FILENAME = *"$EXCLUE_FILENAMES_CONTAINING"* ]]; then
            prog "$taskpercent" ""
            echo "File has been post-processed by ffmpeg - do not rename."
        else

            RENAME_RESPONSE=`curl -s -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -H "X-Api-Key: $RADARR_API_KEY" \
                -X GET http://$RADARR_HOST:$RADARR_PORT/api/renameMovie?movieId=$ID`

            FILE_ID=`echo $RENAME_RESPONSE | jq '.[].movieFileId'`

            curl -s "http://$RADARR_HOST:$RADARR_PORT/api/v3/command" \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -H "X-Api-Key: $RADARR_API_KEY" \
                --data-binary "{\"name\":\"RenameFiles\",\"movieId\":$ID,\"files\":[$FILE_ID]}" >> /dev/null

        fi
    fi
done

prog "$taskpercent" ""
echo -e "\n Finished."
