#!/usr/bin/env python

# -*- coding: utf-8 -*-
#
# Description:  Sync Plex playlists to shared users.
# Author:       /u/SwiftPanda16
# Requires:     plexapi, requests, xmltodict

import requests
import xmltodict
from plexapi.server import PlexServer

### EDIT SETTINGS ###
PLEX_URL = 'http://127.0.0.1:32400'
PLEX_TOKEN = ''

## Sync has been defined below in line 80.
#PLAYLISTS = ['Playlist 1', 'Playlist 2', 'Playlist 3']  # List of playlists to sync
#USERS = ['User 1', 'User 2', 'User 3']  # List of users to sync the playlists to


## CODE BELOW ##

def fetch_plex_api(path='', method='GET', plextv=False, **kwargs):
    """Fetches data from the Plex API"""

    url = 'https://plex.tv' if plextv else PLEX_URL.rstrip('/')

    headers = {'X-Plex-Token': PLEX_TOKEN,
               'Accept': 'application/json'}

    params = {}
    if kwargs:
        params.update(kwargs)

    try:
        if method.upper() == 'GET':
            r = requests.get(url + path,
                             headers=headers, params=params, verify=False)
        elif method.upper() == 'POST':
            r = requests.post(url + path,
                              headers=headers, params=params, verify=False)
        elif method.upper() == 'PUT':
            r = requests.put(url + path,
                             headers=headers, params=params, verify=False)
        elif method.upper() == 'DELETE':
            r = requests.delete(url + path,
                                headers=headers, params=params, verify=False)
        else:
            print("Invalid request method provided: {method}".format(method=method))
            return

        if r and len(r.content):
            if 'application/json' in r.headers['Content-Type']:
                return r.json()
            elif 'application/xml' in r.headers['Content-Type']:
                return xmltodict.parse(r.content)
            else:
                return r.content
        else:
            return r.content

    except Exception as e:
        print("Error fetching from Plex API: {err}".format(err=e))

def get_user_tokens(server_id):
    api_users = fetch_plex_api('/api/users', plextv=True)
    api_shared_servers = fetch_plex_api('/api/servers/{server_id}/shared_servers'.format(server_id=server_id), plextv=True)
    user_ids = {user['@id']: user.get('@username', user.get('@title')) for user in api_users['MediaContainer']['User']}
    users = {user_ids[user['@userID']]: user['@accessToken'] for user in api_shared_servers['MediaContainer']['SharedServer']}
    return users
    
def main():
    """Main script"""
    plex = PlexServer(PLEX_URL, PLEX_TOKEN)

    PLAYLISTS = [x.title for x in plex.playlists()]
    USERS = [x.title for x in plex.myPlexAccount().users()]

    plex_users = get_user_tokens(plex.machineIdentifier)

    plex_playlists = {playlist.title: playlist.items() for playlist in plex.playlists()}

    for playlist in PLAYLISTS:
        playlist_items = plex_playlists.get(playlist)
        if not playlist_items:
            print("Playlist '{playlist}' not found on the server. Skipping.".format(playlist=playlist))
            continue

        print("Cloning the '{title}' playlist...".format(title=playlist))

        for user in USERS:
            user_token = plex_users.get(user)
            if not user_token:
                print("...User '{user}' not found in shared users. Skipping.".format(user=user))
                continue

            user_plex = PlexServer(PLEX_URL, user_token)

            # Delete the old playlist
            try:
                user_playlist = user_plex.playlist(playlist)
                user_playlist.delete()
            except:
                pass

            # Create a new playlist
            user_plex.createPlaylist(playlist, playlist_items)
            print("...Created playlist for '{user}'.".format(user=user))

    return

if __name__ == "__main__":
    main()
    print("Done.")