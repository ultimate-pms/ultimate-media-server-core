#!/bin/bash
#
# qBitTorrent script to automatically remove any completed downloads from matching category (tv|movies) after X hours.
# (The idea behind this is to allow Radarr/Sonar to copy & rename files, then this script will come and remove them after X hours so they still have time to seed.)
#
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
#########################################################################################################

QBITTORRENT_HOSTNAME="localhost:8080"
QBITTORRENT_USERNAME=""
QBITTORRENT_PASSWORD=""

MOVIE_CATAGORY="movies"
TV_CATAGORY="tv"

REMOVE_AFTER_X_HOURS=720 # Suggest at least 24 hours, so that you maintain a reasonable seed ratio... Defaults to 1 month.
DELETE_FILES_FROM_QBTORRENT="true" # Set to true if you want it to delete any remaining files in the qbittorrent downloads directory...

# qBitTorrent 4.5.x and newer now needs to use a cookie to access the API...
COOKIE_TOKEN=`curl \
    --header "Referer: http://$QBITTORRENT_HOSTNAME" \
    --data "username=$QBITTORRENT_USERNAME&password=$QBITTORRENT_PASSWORD" \
    -S -c - "$QBITTORRENT_HOSTNAME/api/v2/auth/login" | grep HttpOnly | awk '{print $6 "=" $7}'`

#########################################################################################################
#
## MOVIE TORRENTS
# ------------------------------------------------------------------------------------------------------------

COMPLETED_MOVIES=`curl --cookie "$COOKIE_TOKEN" -s "http://$QBITTORRENT_HOSTNAME/api/v2/torrents/info?filter=completed&category=$MOVIE_CATAGORY"`

# Radarr client copies the movies, but does not remove the torrent file or the movie file, instead it creates a hardlink so the file can continue to seed...
# Find any torrents older than X hours (after they have been copied over to the NAS volumes), go ahead and remove the torrents and files (in this case symlinks, your copied files will not be removed)...

echo $COMPLETED_MOVIES | jq -r '.[] | [.save_path + .name, .hash, .completion_on|tostring] | @tsv' |
while IFS=$'\t' read -r item hash completion_on; do

    COMPLETED_DATE=`date -d @$completion_on "+%Y-%m-%d %H:%M:%S"`
    CURRENT_DATE=`date "+%Y-%m-%d %H:%M:%S"`

    HOURS_OLD=`echo $(( ( $(date -ud "$CURRENT_DATE" +'%s') - $(date -ud "$COMPLETED_DATE" +'%s') )/60/60 ))`

    if (( $HOURS_OLD > $REMOVE_AFTER_X_HOURS )); then

        echo "Removing: [$item]"
        # Remove from torrent client...
        curl --cookie "$COOKIE_TOKEN" -s "http://$QBITTORRENT_HOSTNAME/api/v2/torrents/delete?hashes=$hash&deleteFiles=$DELETE_FILES_FROM_QBTORRENT"

        # Remove seed files...
        rm -rf $item

    fi
done

## TV TORRENTS
# ------------------------------------------------------------------------------------------------------------

COMPLETED_TV_SERIES=`curl --cookie "$COOKIE_TOKEN" -s "http://$QBITTORRENT_HOSTNAME/api/v2/torrents/info?filter=completed&category=$TV_CATAGORY"`

echo $COMPLETED_TV_SERIES | jq -r '.[] | [.save_path + .name, .hash, .completion_on|tostring] | @tsv' |
while IFS=$'\t' read -r item hash completion_on; do

    COMPLETED_DATE=`date -d @$completion_on "+%Y-%m-%d %H:%M:%S"`
    CURRENT_DATE=`date "+%Y-%m-%d %H:%M:%S"`

    HOURS_OLD=`echo $(( ( $(date -ud "$CURRENT_DATE" +'%s') - $(date -ud "$COMPLETED_DATE" +'%s') )/60/60 ))`

    if (( $HOURS_OLD > $REMOVE_AFTER_X_HOURS )); then

        echo "Removing: [$item]"

        # Remove from torrent client...
        curl --cookie "$COOKIE_TOKEN" -s "http://$QBITTORRENT_HOSTNAME/api/v2/torrents/delete?hashes=$hash&deleteFiles=$DELETE_FILES_FROM_QBTORRENT"

        # Remove seed files...
        rm -rf $item

    fi
done