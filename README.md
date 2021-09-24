# nginx unit php8.0

Completely autonomous docker image with unit-1.25.0 and php8.0 installed.
Based on ubuntu hirsute.

At build time, the container automatically builds the package unit-php for 8.0 version from source and installs it.

# how to use
1. Set base image
2. Install php8.0 modules if you need it
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
    <php8.0 modules>
    
...
    
ADD ./.docker/conf/unit/config.json /tmp/config.json
    
...
    
RUN unitd \
    && curl -X PUT --data-binary @/tmp/config.json --unix-socket \
    /var/run/control.unit.sock http://localhost/config/ \
    && kill `pidof unitd` && cat /var/log/unit.log

CMD ["unitd", "--no-daemon"]
```
