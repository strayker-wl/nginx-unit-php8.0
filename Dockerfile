ARG ubuntu_release='jammy'
ARG tz='Europe/Moscow'
ARG unit_version='1.27.0'
ARG php_version='8.0'

FROM ubuntu:$ubuntu_release as builder

ARG ubuntu_release
ARG tz
ARG unit_version
ARG php_version

ENV TZ=$tz

ADD ./DEBIAN/control /tmp/control

RUN sed -i -e "s:{php_version}:$php_version:g" -e "s:{ubuntu_release}:$ubuntu_release:g" \
    -e "s:{unit_version}:$unit_version:g" /tmp/control

RUN cat /tmp/control

RUN set -xe \
    && echo $TZ > /etc/timezone \
    && apt-get -y update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    gnupg wget curl software-properties-common build-essential \
    && add-apt-repository ppa:ondrej/php \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends php$php_version php$php_version-dev libphp$php_version-embed

RUN curl https://unit.nginx.org/keys/nginx-keyring.gpg | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $ubuntu_release unit \
    deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $ubuntu_release unit" \
    | tee -a /etc/apt/sources.list.d/unit.list \
    && apt-get -y update \
    && apt-get -y install unit \
    && unitd --version

RUN export UNITTMP=$(mktemp -d -p /tmp -t unit.XXXXXX) \
    && mkdir -p $UNITTMP/unit-php$php_version/DEBIAN \
    && cd $UNITTMP \
    && curl -O https://unit.nginx.org/download/unit-$unit_version.tar.gz \
    && tar xzf unit-$unit_version.tar.gz \
    && cd unit-$unit_version \
    && ./configure --prefix=/usr --state=/var/lib/unit --control=unix:/var/run/control.unit.sock --pid=/var/run/unit.pid --log=/var/log/unit.log --tmp=/var/tmp --user=unit --group=unit --tests --openssl --modules=/usr/lib/unit/modules --libdir=/usr/lib/x86_64-linux-gnu --cc-opt='-g -O2 -ffile-prefix-map=/data/builder/debuild/unit-$unit_version/pkg/deb/debuild/unit-$unit_version=. -flto=auto -ffat-lto-objects -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    && ./configure php --module=php$php_version --config=php-config \
    && make php$php_version \
    && mkdir -p $UNITTMP/unit-php$php_version/usr/lib/unit/modules \
    && mv build/php$php_version.unit.so $UNITTMP/unit-php$php_version/usr/lib/unit/modules \
    && touch $UNITTMP/unit-php$php_version/DEBIAN/control \
    && mv /tmp/control $UNITTMP/unit-php$php_version/DEBIAN/control \
    && cat $UNITTMP/unit-php$php_version/DEBIAN/control \
    && dpkg-deb -b $UNITTMP/unit-php$php_version \
    && cp $UNITTMP/unit-php$php_version.deb /tmp/unit-php$php_version.deb

FROM ubuntu:$ubuntu_release

ARG ubuntu_release
ARG tz
ARG unit_version
ARG php_version

ENV TZ=$tz

COPY --from=builder /tmp/unit-php$php_version.deb /tmp/unit-php$php_version.deb

RUN set -xe \
    && echo $TZ > /etc/timezone \
    && apt-get -y update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    gnupg wget curl software-properties-common \
    && add-apt-repository ppa:ondrej/php \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends php$php_version libphp$php_version-embed \
    && curl https://unit.nginx.org/keys/nginx-keyring.gpg | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $ubuntu_release unit \
    deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ $ubuntu_release unit" \
    | tee -a /etc/apt/sources.list.d/unit.list \
    && apt-get -y update \
    && apt-get -y install unit \
    && dpkg -i /tmp/unit-php$php_version.deb \
    && unitd --version
