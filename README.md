# nginx unit with php

Completely autonomous multy-version docker image with nginx unit and php installed.
Based on ubuntu.

At build time, the container automatically builds the package unit-php for php from source and installs it.

# how to build local

0. copy .env.example file as .env file in root dir of project (near .env.example)
1. set versions of ubuntu, php and nginx unit in .env file
2. set image tag name in .env file
3. use bash command `make build`

# how to use
1. Set base image
2. Install php modules if you need it
3. Add nginx-unit config as json file in tmp folder into container
4. Apply nginx-unit config
5. Start unitd

Example:
```dockerfile
FROM strayker/nginx-unit-php8.0:latest

...

RUN set -xe \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends \
    <php modules>
    
...
    
ADD ./.docker/conf/unit/config.json /tmp/config.json
    
...
    
RUN unitd \
    && curl -X PUT --data-binary @/tmp/config.json --unix-socket \
    /var/run/control.unit.sock http://localhost/config/ \
    && kill `pidof unitd`

CMD ["unitd", "--no-daemon"]
```
