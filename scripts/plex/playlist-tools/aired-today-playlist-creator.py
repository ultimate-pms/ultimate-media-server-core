#!/usr/bin/env python

"""
Create a Plex Playlist with what aired on this day in history (month-day), sort by oldest first.
If Playlist from yesterday exists delete and create today's.
If today's Playlist exists exit.
"""

import operator
from plexapi.server import PlexServer
import requests
import datetime

PLEX_URL = 'http://127.0.0.1:32400'
PLEX_TOKEN = ''

LIBRARY_NAMES = ['TV Shows'] # Your library names (comma separated)

today = datetime.datetime.now().date()

PLAYLIST_TITLE = 'Aired Today'

plex = PlexServer(PLEX_URL, PLEX_TOKEN)

def remove_old():
    # Remove old Aired Today Playlists
    for playlist in plex.playlists():
        if playlist.title.startswith(PLAYLIST_TITLE):
            playlist.delete()

def get_all_content(library_name):
    # Get all movies or episodes from LIBRARY_NAME
    child_lst = []
    for library in library_name:
        for child in plex.library.section(library).all():
            if child.type == 'movie':
                child_lst += [child]
            elif child.type == 'show':
                child_lst += child.episodes()
            else:
                pass
    return child_lst


def find_air_dates(content_lst):
    # Find what aired with today's month-day
    aired_lst = []
    for video in content_lst:
        try:
            ad_month = str(video.originallyAvailableAt.month)
            ad_day = str(video.originallyAvailableAt.day)
            
            if ad_month == str(today.month) and ad_day == str(today.day):
                aired_lst += [[video] + [str(video.originallyAvailableAt)]]
        except Exception as e:
            # print(e)
            pass
        
        # Sort by original air date, oldest first
        aired_lst = sorted(aired_lst, key=operator.itemgetter(1))

    # Remove date used for sorting
    play_lst = [x[0] for x in aired_lst]
    return play_lst


remove_old()
play_lst = find_air_dates(get_all_content(LIBRARY_NAMES))
# Create Playlist
if play_lst:
    plex.createPlaylist(PLAYLIST_TITLE, play_lst)
else:
    print('Found nothing aired on this day in history.')