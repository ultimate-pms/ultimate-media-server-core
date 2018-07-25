#!/bin/bash
#
# I love my lists - but I don't like searching for movies older than year 2000 - Generally anything older than this I've already got :)
# This is a quick script to go and blow away any movies that have been added into Radarr each night (via a List) and remove them if they have not yet been downloaded...
#
################################################################################################

RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"

CUTOFF_YEAR="1992" # Removes any 'un-downloaded' movies prior to this year.
DELETE_FLAGS="?deleteFiles=false&addExclusion=true" # You may also add true/false flags for the query strings: deleteFiles, addExclusion

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

# Check JQ Installed first
jqInstalled

echo -e "++ Radarr Old Movie Remover ++\n------------------------------\n\n"
echo "Querying API for complete movie collection ..."

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
    MOVIEYEAR=`echo $(_jq '.year')`
    DOWNLOADED=`echo $(_jq '.downloaded')`
    ID=`echo $(_jq '.id')`

    # Simple progress bar so we know how far through the script we are (great for large collections)...
    taskpercent=$((i*100/total))
    prog "$taskpercent" $MOVIENAME...

    # Only remove if not downloaded yet, and older than the cutoff year
    if [ "$DOWNLOADED" == "false" ]; then

        if [ $MOVIEYEAR -lt $CUTOFF_YEAR ]; then
            prog "$taskpercent" ""
            echo "FOUND: $MOVIENAME, older than year $CUTOFF_YEAR & not downloaded ... removing"

            curl -s -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                --data "content=success" \
                -H "X-Api-Key: $RADARR_API_KEY" \
                -X DELETE http://$RADARR_HOST:$RADARR_PORT/api/movie/$ID$DELETE_FLAGS
        fi
    fi
done

prog "$taskpercent" ""
echo -e "\n Finished."
