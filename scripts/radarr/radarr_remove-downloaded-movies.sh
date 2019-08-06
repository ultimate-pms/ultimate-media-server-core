#!/bin/bash
#
# Script to removed files that are already downloaded with quality greater than 1080p and older than 2 years.
#
#
# Author: DN later edtited by 12Nick12
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################
RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"
RADARR_URI="radarr"

CUTOFF_QUALITY="Bluray-1080p"
logFile="/var/log/radarr_clean-$(date +'%Y%m%d_%H%M%S').log"
MAX_SIZE="6"
DELETE_FLAGS="?deleteFiles=false&addExclusion=true" # You may also add true/false flags for the query strings: deleteFiles, addExclusion
curYear=$(date +'%Y')
################################################################################################

MAX_SIZE=$(echo "$MAX_SIZE * 1073741824" | bc)
CUTOFF_YEAR=$((curYear-2))

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

# Check JQ Installed first
jqInstalled

echo -e "++ Radarr Remove downloaded movies meeting 1080p BluRay ++\n------------------------------\n\n"
echo "Querying API for complete movie collection ..."

TOTALITEMS=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -X GET http://$RADARR_HOST:$RADARR_PORT/$RADARR_URI/api/movie`

i=0
total=`echo $TOTALITEMS | jq '. | length'`
echo -e "\nProcessing results:"

for row in $(echo "${TOTALITEMS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | /usr/bin/base64 --decode | /usr/bin/jq -r ${1}
    }
    i=$((i + 1))

    MOVIENAME=`echo $(_jq '.title')`
    MOVIEYEAR=`echo $(_jq '.year')`
    DOWNLOADED=`echo $(_jq '.downloaded')`
    HASFILE=`echo $(_jq '.hasFile')`
    QUALITY=`echo $(_jq '.movieFile.quality.quality.name')` # Needs to equal Bluray-1080p to be what I want
    SIZE=`echo $(_jq '.movieFile.size')` # Should be above 4*1073741824
    ID=`echo $(_jq '.id')`

    # Simple progress bar so we know how far through the script we are (great for large collections)...
    taskpercent=$((i*100/total))
    prog "$taskpercent" $MOVIENAME...

    # Only remove if not downloaded yet, and older than the cutoff year
    if [ "$DOWNLOADED" == "true" ]; then

	if [ "$MOVIEYEAR" -lt "$CUTOFF_YEAR" ]; then

	        if [ "$QUALITY" == "$CUTOFF_QUALITY" ]; then

			if [ "$SIZE" -ge "$MAX_SIZE" ]; then
		            prog "$taskpercent" ""
		            echo "FOUND: $MOVIENAME, has $QUALITY, is "$(bc <<< "scale=2 ; $SIZE / 1073741824")" GB from year $MOVIEYEAR and is downloaded ... removing" | tee -a "${logFile}"

	                    curl -s -H "Accept: application/json" \
	                        -H "Content-Type: application/json" \
	                        --data "content=success" \
	                        -H "X-Api-Key: $RADARR_API_KEY" \
	                        -X DELETE http://$RADARR_HOST:$RADARR_PORT/$RADARR_URI/api/movie/$ID$DELETE_FLAGS
			fi
		fi
        fi
    fi
done

prog "$taskpercent" ""
echo -e "\n Finished."
