FROM ubuntu:hirsute

ARG tz="Europe/Moscow"

ENV TZ=$tz

ADD ./DEBIAN/control /tmp/control

RUN set -xe \
    && echo $TZ > /etc/timezone \
    && apt-get -y update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    gnupg wget curl software-properties-common build-essential \
    && add-apt-repository ppa:ondrej/php \
    && apt-get -y update \
    && apt-get -y install --no-install-recommends php8.0 php8.0-dev libphp8.0-embed

RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add - \
    && echo "deb https://packages.nginx.org/unit/ubuntu/ hirsute unit \
    deb-src https://packages.nginx.org/unit/ubuntu/ hirsute unit"  | tee -a /etc/apt/sources.list.d/unit.list \
    && apt-get -y update \
    && apt-get -y install unit \
    && unitd --version

RUN export UNITTMP=$(mktemp -d -p /tmp -t unit.XXXXXX) \
    && mkdir -p $UNITTMP/unit-php8.0/DEBIAN \
    && cd $UNITTMP \
    && curl -O https://unit.nginx.org/download/unit-1.25.0.tar.gz \
    && tar xzf unit-1.25.0.tar.gz \
    && cd unit-1.25.0 \
    && ./configure --prefix=/usr --state=/var/lib/unit --control=unix:/var/run/control.unit.sock --pid=/var/run/unit.pid --log=/var/log/unit.log --tmp=/var/tmp --user=unit --group=unit --tests --openssl --modules=/usr/lib/unit/modules --libdir=/usr/lib/x86_64-linux-gnu --cc-opt='-g -O2 -ffile-prefix-map=/data/builder/debuild/unit-1.25.0/pkg/deb/debuild/unit-1.25.0=. -flto=auto -ffat-lto-objects -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    && ./configure php --module=php8.0 --config=php-config \
    && make php8.0 \
    && mkdir -p $UNITTMP/unit-php8.0/usr/lib/unit/modules \
    && mv build/php8.0.unit.so $UNITTMP/unit-php8.0/usr/lib/unit/modules \
    && touch $UNITTMP/unit-php8.0/DEBIAN/control \
    && mv /tmp/control $UNITTMP/unit-php8.0/DEBIAN/control \
    && cat $UNITTMP/unit-php8.0/DEBIAN/control \
    && dpkg-deb -b $UNITTMP/unit-php8.0 \
    && dpkg -i $UNITTMP/unit-php8.0.deb
