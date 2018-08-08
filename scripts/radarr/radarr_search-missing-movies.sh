#!/bin/bash
#
# Script that hits the Radarr API to search for any missing movies
# Ideally this should be scheduled with your CRON and run each night
# 
# Author: David Nedved
# https://github.com/david-nedved/ultimate-plex-setup/
#
################################################################################################

RADARR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
RADARR_HOST="127.0.0.1"
RADARR_PORT="7878"

################################################################################################

curl "http://$RADARR_HOST:$RADARR_PORT/api/command" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json, text/javascript, */*; q=0.01' \
 -H "X-Api-Key: $RADARR_API_KEY" \
 --data-binary '{"name":"missingMoviesSearch","filterKey":"monitored","filterValue":"true"}' --compressed
