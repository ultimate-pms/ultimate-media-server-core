FROM ubuntu:16.04

RUN apt update && \
    apt install git curl -y && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt install -y nodejs

RUN cd /opt && \
    git clone https://github.com/ultimate-pms/UnicornLoadBalancer.git && \
    cd UnicornLoadBalancer && git checkout dev && npm install && \
    npm install -g nodemon forever

WORKDIR /opt/UnicornLoadBalancer

# Run healthcheck against localhost every 5 seconds to check the load balancer is still healthy
HEALTHCHECK --interval=5s --timeout=5s --retries=3 CMD curl --fail http://localhost:3001/ || exit 1

# Run the service (npm start) via nodemon to restart if crashing...
ENTRYPOINT ["npm", "start"]