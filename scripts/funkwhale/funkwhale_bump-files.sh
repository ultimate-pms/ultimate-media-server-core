#!/bin/bash
#
# Quick script to run a funkwhale import and then use eyeD3 to fix any known errors.
#
# NB: A lot of these errors will be fixed in future funkwhale builds...
#     be prepared to run any failed tracks through beets to re-add the removed metadata & run a re-import on your media in the future.
#
################################################################################################

IDENTIFIER=`echo "$BASHPID.import"`
FUNKWHALE_PATH_SEARCH="- /srv/funkwhale/data/music/"
FUNKWHALE_PATH_REPLACE="/nas/bay-1/Music/"

# I'm using funkwhale via docker, you will need to adapt this if you're not using funkwhale in docker..
(cd /opt/docker-funkwhale/; docker-compose run --name="$IDENTIFIER" api python manage.py import_files "/srv/funkwhale/data/music/**/*.mp3" --recursive --noinput --in-place)

# Get import logs
docker logs "$IDENTIFIER" > "/tmp/$IDENTIFIER"

# Cleanup
docker stop "$IDENTIFIER" && docker rm "$IDENTIFIER"

# We only care about failed results ... Remove any other results from log...
sed -i '/could not be imported/,$!d' "/tmp/$IDENTIFIER"
sed -i '/could not be imported/d' "/tmp/$IDENTIFIER"
sed -i '/please refer to import batch/d' "/tmp/$IDENTIFIER"

# Remove special characters (colours etc) from logs
sed -ri "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" "/tmp/$IDENTIFIER"

removeMonthTag() {
    echo "Removing Month Tag from: $1" >> /var/log/eyed3.log
    eyeD3 --remove-frame TDAT "$1"
}

stripLongTags() {
    echo "LONG ID3 TAG FOUND: $1" >> /var/log/eyed3.log

    truncateArtistTag() {
        ARTISTS=`ffprobe "$1" 2>&1 | grep -i "Artists" | cut -d ':' -f 2 | cut -c 2-`
        WC=`echo $ARTISTS | wc -c`

        if [ $WC -gt 255 ]; then
            # Cut the artist tag at 255 characters
            TRUNCATED_ARTISTS=`echo "$ARTISTS" | cut -c -255`

            # Then strip out anything past the last divider (/) - This way we're not stuck with half an artist name
            CLEANED_ARTIST_TAG=`echo "$TRUNCATED_ARTISTS" | rev | cut -d"/" -f2-  | rev`

            eyeD3 --artist "$CLEANED_ARTIST_TAG" "$1"
        fi
    }

    # Is it an artist tag?
    truncateArtistTag "$1"
}

multipleArtists() {
    echo "MULTIPLE ARTISTS: $1" >> /var/log/eyed3.log
    #eyeD3 --remove-frame TDAT "$1"
}

cantParseString() {
    echo "Removing Month Tag from: $1" >> /var/log/eyed3.log
    eyeD3 "$1" 2>&1 | grep -zqv "Invalid v2.3 TYER, TDAT, or TIME" && echo "unknown method" || eyeD3 --remove-frame TDAT "$1"
}

while IFS='' read -r line || [[ -n "$line" ]]; do

    TRACK_LOG=`echo "${line/$FUNKWHALE_PATH_SEARCH/$FUNKWHALE_PATH_REPLACE}"`
    LOG_ERROR=`echo "$TRACK_LOG" | rev | cut -d: -f1 | rev`
    LOG_FILE=`echo "$TRACK_LOG" | rev | cut -d: -f2 | rev`

    # Known errors and scriptable fixes...
    ## Month is missing fix...
    printf "$LOG_ERROR" | grep -zqv "month must be in 1..12" && echo passed || removeMonthTag "$LOG_FILE"

    ## If the ID3 tag has a field longer than 255
    printf "$LOG_ERROR" | grep -zqv "value too long for type character varying(255)" && echo passed || stripLongTags "$LOG_FILE"

    ## If multiple artists run through beets with the plugin to merge artists enabled...
    printf "$LOG_ERROR" | grep -zqv "returned more than one Artist" && echo passed || multipleArtists "$LOG_FILE"

    ## If multiple artists run through beets with the plugin to merge artists enabled...
    printf "$LOG_ERROR" | grep -zqv "ParserError Unable to parse string" && echo passed || cantParseString "$LOG_FILE"


done < "/tmp/$IDENTIFIER"