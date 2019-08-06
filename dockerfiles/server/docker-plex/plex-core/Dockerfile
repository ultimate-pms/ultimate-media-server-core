FROM plexinc/pms-docker:1.14.1.5488-cc260c476

# Plex Media server (from official plex docker build) with the Unicorn Load balancer
# (for multiple plex trandcoding on other hosts) baked in...

RUN apt update && \
    apt install git curl -y && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt install -y nodejs

RUN cd /opt && \
    git clone https://github.com/ultimate-pms/UnicornFFMPEG.git && \
    cd UnicornFFMPEG && git checkout dev && npm install && \
    npm start && \
    mv "/usr/lib/plexmediaserver/Plex Transcoder" "/usr/lib/plexmediaserver/Plex Transcoder-old" && \
    cp "/opt/UnicornFFMPEG/bin/Plex Transcoder-linux" "/usr/lib/plexmediaserver/Plex Transcoder"