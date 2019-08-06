FROM ubuntu:16.04

RUN apt update && \
    apt install git curl -y && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt install -y nodejs

RUN cd /opt && \
    git clone https://github.com/ultimate-pms/UnicornTranscoder.git && \
    cd UnicornTranscoder && git checkout dev && npm install && \
    npm run install --force && \
    mkdir -p cache

WORKDIR /opt/UnicornTranscoder
RUN echo '#!/bin/bash\n\nmkdir -p /opt/UnicornTranscoder/plexmediaserver/$PLEX_BUILD/usr/lib/\nln -s /usr/lib/plexmediaserver /opt/UnicornTranscoder/plexmediaserver/$PLEX_BUILD/usr/lib/plexmediaserver\n\nnpm start' > /opt/UnicornTranscoder/start.sh && \
    chmod +x /opt/UnicornTranscoder/start.sh

# Run healthcheck against localhost every 5 seconds to check the transcoder is still healthy
HEALTHCHECK --interval=5s --timeout=5s --retries=3 CMD curl --fail http://localhost:3000/ || exit 1

# Run the service (npm start) via nodemon to restart if crashing...
ENTRYPOINT ["/opt/UnicornTranscoder/start.sh"]