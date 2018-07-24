#!/bin/bash

# I stupidly added in a list to Radarr that imported thousands of low ranking movies that I didn't want ....
# This is a quick and dirty script to find those movies on the NAS (volume #6) and blow them away if they have not yet been downloaded ...
#
################################################################################################

RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"
ONLY_MATCH_PATH="/nas/bay-6/"

################################################################################################

TOTALITEMS=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -X GET http://$RADARR_HOST:$RADARR_PORT/api/movie`

i=0
for row in $(echo "${TOTALITEMS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | /usr/bin/base64 --decode | /usr/bin/jq -r ${1}
    }
    i=$((i + 1))

    MOVIENAME=`echo $(_jq '.title')`
    DOWNLOADED=`echo $(_jq '.downloaded')`
    PATH=`echo $(_jq '.path')`
    ID=`echo $(_jq '.id')`

    echo "#$i [ID: $ID] - $MOVIENAME"

    if [ "$DOWNLOADED" == "false" ]; then
        echo -e "\n>> Movie [$MOVIENAME] not downloaded... Is this in $ONLY_MATCH_PATH?"

        if [[ $PATH = *"$ONLY_MATCH_PATH"* ]]; then
            echo ">> Movie was in $ONLY_MATCH_PATH ... Blow it away!"

            /usr/bin/curl -s -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                --data "content=success" \
                -H "X-Api-Key: $RADARR_API_KEY" \
                -X DELETE http://$RADARR_HOST:$RADARR_PORT/api/movie/$ID

            echo -e ">> REMOVED!\n"

        fi
    fi
done
