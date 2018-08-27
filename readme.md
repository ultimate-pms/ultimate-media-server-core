# The Ultimate Media Server Setup!
This repo is a work-in-progress... If you have any additions, please feel free to submit a PR!

The aim of this project, is to build your perfect media server setup with end-to-end automation in an evening, not weeks - I'll be updating this repo as my own setup evolves, but for now here's a "dump" to help you get the perfect PMS setup!
If you're new to this, you should clone down the repo, and start by standing up all the various services within Docker - This is the easiest way to get running...

--------------------------------------------

### My _almost_ perfect media server setup consists of:

- [PLEX!](https://plex.tv/) - If you don't know what Plex is, you should start here - Plex is the ultimate Media Server, with apps for iOS, Android, numerous smart TV's and all the rest - It's truly a one-stop media shop.
- [Sonarr](https://sonarr.tv/) - Automatically grabs your favourite TV shows, sends them to your download client & organises the files.
- [Radarr](https://radarr.video/) - A fork of Sonarr, but for Movies.
- [Lidarr](https://lidarr.audio/) - A fork of Sonarr, but for all your favorite music - Great for pulling in AAC/FLAC tracks that you can't get on Spotify if you're an Audiophile.
- [qBittorrent](https://www.qbittorrent.org/)  - Reliable, lightweight linux torrent client
- [Jackett](https://github.com/Jackett/Jackett) - API integration of all of the most popular Torrent Trackers for Sonarr/Radarr.
- [Tautulli](https://tautulli.com/) - A monitoring and tracking tool for Plex (Think of this as Google Analytics for Plex)
- [PlexConnect](https://github.com/iBaa/PlexConnect) - Hijacks the trailers app on your AppleTV 2/3 (and replaces it with Plex) 
- [Ombi](https://ombi.io/) - Great way for your friends/family to request (and automate) adding new content to your Plex Server
- [Openspeedtest](http://openspeedtest.com/) - Handy to have to test the upload/download speed for your friends/family streaming from you.

So without further mention, let's dive in and get the thing up and running!
(Docker-compose files are based upon the components mentioned above)

--------------------------------------------

## 1. Clone Repo:

The project uses Git Submodules, make sure you clone the repo using:
`git clone --recurse-submodules https://github.com/ultimate-pms/ultimate-plex-setup.git /opt/pms-scripts`

## 2. Setup services:
### 2.1 Install Docker & Docker Compose:

See here for Docker: https://www.docker.com/get-started
For Docker-compose: https://docs.docker.com/compose/install/

### 2.2 Install Plex & other applications mentioned

**NOTE:** Before running this, you should configure each docker-compose file accordingly!
By default everything will mount to a volume called `/nas` which should be a network s hare to your NAS/External Drive(s)...
Docker compose files are located in the `dockerfiles/server` directory.

```
# Copy compose files into /opt
cp -rp /opt/pms-scripts/dockerfiles/server/* /opt/

# Stand up each container... (go grab a coffee, this will take a while)
find /opt/ -maxdepth 1 -name "docker*" -type d \( ! -wholename /opt/ \) -exec bash -c "cd '{}' && docker-compose up -d" \;

```

## 3. Configure!

You'll now need to go and configure each service - there's various howto's on the Internet already, when I've got time I'll do a write up.

Useful URLs:
 - Jackett - `http://<server-ip>:9117/UI/Dashboard` - Start here, configure your torrent indexers to start...
 - qBittorrent - `http://<server-ip>:8080/` - This is your torrent client, you will ned to configure save-file location, password etc...
 - tvHeadend - `http://<server-ip>:9981/` - You'll need to configure tvHeadend with your favorite IPTV feeds if you want to use the Plex DVR Feature
 - Tautulli - `http://<server-ip>:8181/home` - Analytics about who's watching what media on your network
 - Sonarr - `http://<server-ip>:8988/` - Configure, then add in all your favorite TV series you want to start auto-downloading
 - Radarr `http://<server-ip>:7878/` - Configure Movies you want to start auto-downloading
 - Lidarr `http://<server-ip>:8686/` - Configure for any Music you want to start auto-downloading...
 - Plex - `http://<server-ip>:22500/` - **Access Your Plex Media Server!** (via Nginx proxy injecting TVHeadend CSS Fixes) - You should be port-forwarding to this one and sharing with your friends.
 - OpenSpeedtest - `http://<server-ip>:8081/` - Worth setting up port-forwarding to this, it will allow you to test the download speed (of you internet connection) when accessing your server remotely.
 - Ombi - `http://<server-ip>:3579/` - Worth setting up port-forwarding to this one also - It will allow your friends and family to "request" new Series, Movies etc to be added to your server (This way they don't need access to Radarr/Sonarr/Lidarr)


## 4. Additional Automation & Maintenance Scripts

*NB:* Some of these Scripts you may want to run once off, others you may wish to schedule in a cron.

| Script                                                                               | Language    | Targets          | Description                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------ | ----------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [radarr_rename-movie-files.sh](scripts/radarr/radarr_rename-movie-files.sh)                 | Bash        | Radarr (API)     | Quick and dirty script to hit the Radarr API and rename any movies (via the Radar API) so that they are correctly indexed in Plex
| [radarr_search-missing-movies.sh](scripts/radarr/radarr_search-missing-movies.sh)           | Bash        | Radarr (API)     | Script that hits the Radarr API to search for any missing movies (Ideally this should be scheduled with your CRON and run each night)
| [radarr_search-missing-movies-by-year](scripts/radarr/radarr_search-missing-movies-by-year.sh) | Bash     | Radarr (API)     | Same as previous script, but only searches missing movies that match a specific year (i.e. Only search missing movies from 2016)
| [radarr_cleanup-crappy-movies.sh](scripts/radarr/radarr_cleanup-crappy-movies.sh)           | Bash        | Radarr (API)     | I stupidly added in a list to Radarr that imported thousands of low ranking movies that I didn't want .... This is a quick and dirty script to find those movies on the NAS and blow them away if not yet downloaded
| [radarr_remove-undownloaded-movies.sh](scripts/radarr/radarr_remove-undownloaded-movies.sh) | Bash        | Radarr (API)     | I love my lists - but I don't like searching for movies older than year 1992 - Script finds any un-downloaded movies (auto populated from a list) and removes them
| [radarr_bulk-import-movies-hack.md](scripts/radarr/radarr_bulk-import-movies-hack.md)       | Javascript  | Radarr (Browser) | If you're like me and trying to import thousands of pre-downloaded movies (around 4,000+ movies) into Radarr, you're not going to want to click through the web-ui manually and add them all...
| [fake-video-detector](https://github.com/ultimate-pms/fake-video-detector)                  | Mixed       | CLI              | Automatically detect fake videos in your library based upon a 'database' of blacklisted videos
| [remove-completed-downloads](scripts/qbittorrent/qb_remove-completed-downloads.sh)          | Bash        | qBitTorrent      | qBitTorrent script to automatically remove any completed downloads from matching category (tv|movies) after X hours (The idea behind this is to allow Radarr/Sonar to copy & rename files, then this script will come and remove them after X hours so they still have time to seed)
| [convert-to-mp4](scripts/post-processing/convert-to-mp4.sh)                                 | Bash        | N/A              | Post processing script that you can hook into Radarr (or run on your filesystem via `run-nas.sh`) that converts all your video files into mp4 containers - *NO TRANSCODING IS DONE*, The original transcoding, subtitles, audio channels etc are all copied as is - This is a must have as Plex prefers to "direct stream" any content in MP4 format
| [remove-embedded-mobie-titles](scripts/post-processing/remove-embedded-movie-titles.sh)     | Bash        | N/A              | Post processing script that goes and strips any Metadata titles out of your video file names - This is great if your TV/Movie organizer (Radarr/Sonarr etc) is setup to rename your files as Plex will use the file name to sort Movie/TV not title that is in the file's metadata.
| [lidarr_search-missing-tracks](scripts/lidarr/lidarr_search-missing-tracks.sh)              | Bash        | Lidarr (API)     | Script to go and hit the Lidarr API (suggest scheduling via a cron each night) to "force search" for any missing tracks against your indexers...
| [lidarr_last-fm-adder](scripts/lidarr/lidarr_last-fm-adder.sh)                              | Bash        | Lidarr (API)     | Script to query the last.fm API and return new artists to add into your Lidarr search Library...
| [lidarr_refresh-filesystem](scripts/lidarr/lidarr_refresh-filesystem.sh)                    | Bash        | Lidarr (API)     | Iterates through each and every one of your Lidarr artists and triggers a refresh of files on on your filesystem (Useful if you add/update your music library outside of Lidarr so that Lidarr is kept in-sync with new music added)

Here's a copy of my current cron jobs -- update paths accordingly:

```
### Various cron jobs to make Plex Life easier ...

# Remove any old, un-downloaded movies before triggering search-all...
45 2 * * * /opt/pms-scripts/scripts/radarr/radarr_remove-undownloaded-movies.sh

# Trigger nightly 'Search all' in sonarr/radarr/lidarr for any missing series/episodes...
30 1 * * * /opt/pms-scripts/scripts/lidarr/lidarr_search-missing-tracks.sh
0 3 * * * /opt/pms-scripts/scripts/radarr/radarr_search-missing-movies.sh

# Cleanup any completed torrents that have been post processed and are just left seeding...
20 * * * * /opt/pms-scripts/scripts/qbittorrent/qb_remove-completed-downloads.sh

```

### And some more Docker based scripts:

| Script                                                          | Language    | Targets          | Description                                                                                                                                                                                                                                  |
| ----------------------------------------------------------------| ----------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [plex2netflix](dockerfiles/scripts/plex2netflix)                | Nodejs      | Plex (API)       | Dockerised version of the [plex2netflix](https://github.com/SpaceK33z/plex2netflix) NPM which checks how much of your content is on Netflix

