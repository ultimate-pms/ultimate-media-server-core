#!/bin/bash
#
# Plex works best if all your videos are in MP4 format - Most clients support "direct stream" with mp4 files...
#
# Here's a quick script to convert the video container to MP4 and only copy 'english' audio tracks (and remove any others)
# No transcoding is done, so it's pretty quick and should only take 10-20 seconds per video to process.
#
# NB:   Metadata is also deleted "as people often embed funky metadata in the file names etc" which fixes movies
#       from showing up funny in the plex library - This assumes that the files have already been renamed 'cleanly'
#       using a tool like Radarr, or Filebot etc.
# 
# Author: DN
# https://github.com/ultimate-pms/ultimate-plex-setup
#
################################################################################################

DEFAULT_LANGUAGE="eng"
MAP_METADATA_FLAG="" # Set to "-map_metadata -1" to remove metadata or an empty string to copy default metadata over
DELETE_SOURCE_FILES=1 # Set to 0 to disable deleting of the original media

################################################################################################

SOURCE_FILE="$1"

fName=$(basename -- "$SOURCE_FILE")
fExt="${fName##*.}"
fExtLower=`echo "$fExt" | awk '{print tolower($0)}'`

ffMpegInstalled() {
    if ! [ -x "$(command -v ffmpeg)" ]; then
        echo 'Please install ffmpeg to use this script' >&2
        exit 1
    fi
}

if [ "$fExtLower" == "mp4" ]; then
    echo "No need to transform file - file is already in mp4 container."
    exit 0
else
    ffMpegInstalled

    # MAP IN ALL VIDEO TRACKS - Sometimes there is a static JPG DVD Cover etc...
    VIDEO_TRACKS=`ffprobe -hide_banner -show_entries stream=index,codec_name,codec_type:stream_tags=language -of compact "$SOURCE_FILE" -v 0 | grep -i "video" | awk -F "|" '{print $2}'`
    MAP_VIDEO=()
    while read -r track; do
        TRACK_NUMBER=`echo $track | tail -c 2`
        MAP_VIDEO+=(-map 0:$TRACK_NUMBER)
    done <<< "$VIDEO_TRACKS"

    # MAP ALL AUDIO TRACKS (Sometimes there will be director commentary etc)
    AUDIO_TRACKS=`ffprobe -hide_banner -show_entries stream=index,codec_name,codec_type:stream_tags=language -of compact "$SOURCE_FILE" -v 0 | grep -i "audio" | awk -F "|" '{print $2}'`

    MAP_AUDIO=()
    while read -r track; do
        TRACK_NUMBER=`echo $track | tail -c 2`
        MAP_AUDIO+=(-map 0:$TRACK_NUMBER)
    done <<< "$AUDIO_TRACKS"

    # MAP IN ALL SUBTITLE TRACKS
    # Any subtitle formats that are not srt we won't map in ..
    SUBTITLE_TRACKS=`ffprobe -hide_banner -show_entries stream=index,codec_name,codec_type:stream_tags=language -of compact "$SOURCE_FILE" -v 0 | grep -i "subtitle" | grep -i "srt" | awk -F "|" '{print $2}'`

    MAP_SUBTITLES=()
    while read -r track; do
        TRACK_NUMBER=`echo $track | tail -c 2`
        if [ ! -z "$TRACK_NUMBER" ]; then
            # Codec for subtitle tracks with mp4 can be either: copy or mov_text
            MAP_SUBTITLES+=(-map 0:$TRACK_NUMBER )
        fi
    done <<< "$SUBTITLE_TRACKS"
    if [ ! ${#MAP_SUBTITLES[@]} -eq 0 ]; then
        # If subtitles are mapped in, set the codec to something supported in mp4 containers.
        MAP_SUBTITLES+=(-scodec mov_text )
    fi

    ffmpeg -loglevel fatal -hide_banner -i "$SOURCE_FILE" -vcodec copy -acodec copy $MAP_METADATA_FLAG "${MAP_VIDEO[@]}" "${MAP_AUDIO[@]}" "${MAP_SUBTITLES[@]}" -y "${SOURCE_FILE%.*}.mp4"
    exitCode=$?

    if [ $exitCode -eq 0 ]; then
        if [ "$DELETE_SOURCE_FILES" -eq 1 ]; then
            rm -rf "$SOURCE_FILE"
        fi
        exit 0
    else
        exit $exitCode
    fi
fi
