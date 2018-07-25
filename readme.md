# The Ultimate PMS Setup!
This repo is a work-in-progress... If you have any additions, please feel free to submit a PR!

The aim of this project, is to build your perfect media server setup with end-to-end automation in an evening, not weeks - I'll be updating this repo as my own setup evolves, but for now here's a "dump" to help you get the perfect PMS setup!

> I'll be adding Docker Compose files for all the suggested apps listed below in the coming  weeks when I have time, for now here's a copy of some of the more useful script's to help you get started...

--------------------------------------------

### Current Scripts:

*NB:* Some of these Scripts you may want to run once off, others you may wish to schedule in a cron.

| Script                                                                               | Language    | Targets          | Description                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------ | ----------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [radarr_rename-movie-files.sh](scripts/radarr/radarr_rename-movie-files.sh)                 | Bash        | Radarr (API)     | Quick and dirty script to hit the Radarr API and rename any movies (via the Radar API) so that they are correctly indexed in Plex
| [radarr_search-missing-movies.sh](scripts/radarr/radarr_search-missing-movies.sh)           | Bash        | Radarr (API)     | Script that hits the Radarr API to search for any missing movies (Ideally this should be scheduled with your CRON and run each night)
| [radarr_cleanup-crappy-movies.sh](scripts/radarr/radarr_cleanup-crappy-movies.sh)           | Bash        | Radarr (API)     | I stupidly added in a list to Radarr that imported thousands of low ranking movies that I didn't want .... This is a quick and dirty script to find those movies on the NAS and blow them away if not yet downloaded
| [radarr_remove-undownloaded-movies.sh](scripts/radarr/radarr_remove-undownloaded-movies.sh) | Bash        | Radarr (API)     | I love my lists - but I don't like searching for movies older than year 1992 - Script finds any undownloaded movies (auto populated from a list) and removes them
| [radarr_bulk-import-movies-hack.md](scripts/radarr/radarr_bulk-import-movies-hack.md)       | Javascript  | Radarr (Browser) | If you're like me and trying to import thousands of pre-downloaded movies (around 4,000+ movies) into Radarr, you're not going to want to click through the web-ui manually and add them all...

Here's a copy of my current configuration -- update paths accordingly:

```
### Various cron jobs to make Plex better...

# Remove any old, un-downloaded movies before triggering search-all...
45 2 * * * /opt/scripts/_radarr/radarr_remove-undownloaded-movies.sh

# Trigger nightly 'Search all' in sonarr for any missing series/episodes...
0 3 * * * /opt/scripts/_radarr/radarr_search-missing-movies.sh
```

### The Perfect PMS Setup:
In addition to these scripts to better manage your media, you should consider the following - _(All these programs are designed to run in the browser - you don't need a GUI on your server)_:

- [Sonarr](https://sonarr.tv/) - Automatically grabs your favourite TV shows, sends them to your download client & organises the files.
- [Radarr](https://radarr.video/) - A fork of Sonarr, but for Movies.
- [qBittorrent](https://www.qbittorrent.org/)  - Reliable, lightweight linux torrent client
- [Jackett](https://github.com/Jackett/Jackett) - API integration of all of the most popular Torrent Trackers for Sonarr/Radarr.
- [Tautulli](https://tautulli.com/) - A monitoring and tracking tool for Plex (Think of this as Google Analytics for Plex)
- [PlexConnect](https://github.com/iBaa/PlexConnect) - Hijacks the trailers app on your AppleTV 2/3 (and replaces it with Plex) 
- [Ombi](https://ombi.io/) - Great way for your friends/family to request (and automate) adding new content to your Plex Server
- [Openspeedtest](http://openspeedtest.com/) - Handy to have to test the upload/download speed for your friends/family streaming from you.
