#!/bin/bash
#
################################################################################################

RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.01"
RADARR_PORT="7878"

ONLY_MATCH_PATH="/nas/bay-6/"
OLD_BASE_PATH="/nas/bay-7/"
NEW_BASE_PATH="/nas2/bay-3/"

################################################################################################
JQ=`which jq`
BASE64=`which base64`
SED=`which sed`
CURL=`which curl`

TOTALITEMS=`curl -s -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -X GET http://$RADARR_HOST:$RADARR_PORT/api/movie`

function updateItem {

    exec $CURL -s -H "Accept: application/json" \
        -H "Content-ype: application/json" \
        -H "X-Api-Key: $RADARR_API_KEY" \
        -X PUT \
        -d "$2" \
        http://$RADARR_HOST:$RADARR_PORT/api/movie/$1
}

i=0
for row in $(echo "${TOTALITEMS}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | (exec $BASE64 --decode) | (exec $JQ -r ${1})
    }
    i=$((i + 1))

    PATH=`echo $(_jq '.path')`

    if [[ $PATH == *"$OLD_BASE_PATH"* ]] ; then

        MOVIENAME=`echo $(_jq '.title')`
        ID=`echo $(_jq '.id')`

        echo "#$i [ID: $ID] - $MOVIENAME ($PATH)"
        UPDATED_METADATA=`echo ${row} | (exec $BASE64 --decode) | (exec $SED "s#$OLD_BASE_PATH#$NEW_BASE_PATH#g")`
        updateItem $ID "$UPDATED_METADATA" &

    fi

done
