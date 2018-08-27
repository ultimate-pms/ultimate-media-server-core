#!/bin/bash
#
# qBitTorrent script to automatically process any completed audio downloads through "Beets" to cleanup ID3 tags etc.
# 
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
#########################################################################################################

QBITTORRENT_HOSTNAME="localhost:8080"
QBITTORRENT_USERNAME=""
QBITTORRENT_PASSWORD=""

MUSIC_CATAGORY="music"


## MUSIC TORRENTS
# ------------------------------------------------------------------------------------------------------------

COMLETED_MUSIC=`curl -s "http://$QBITTORRENT_USERNAME:$QBITTORRENT_PASSWORD@$QBITTORRENT_HOSTNAME/query/torrents?filter=completed&category=$MUSIC_CATAGORY"`

echo $COMLETED_MUSIC | jq -r '.[] | [.save_path + .name, .hash, .completion_on|tostring] | @tsv' |
while IFS=$'\t' read -r item hash completion_on; do

    echo "Beet Import: [$item]"
    # Import with beet
    docker exec -i beets bash -c \
        "beet -vv import -q -l /config/import.log \"$item\""

    echo "Remove files in: [$item]"
    rm -rf "$item"

    echo "Remove from QBittorrent: [$item]"
    curl -s -d "hashes=$hash" -X POST "http://$QBITTORRENT_USERNAME:$QBITTORRENT_PASSWORD@$QBITTORRENT_HOSTNAME/command/delete"

done
