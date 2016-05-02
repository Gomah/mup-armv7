#
# MUP Dockerfile for armv7
#

# Pull base image.
FROM debian:jessie
MAINTAINER Thomas M <web@gomah.fr> (@gomah)

RUN apt-get update && apt-get install -y wget && apt-get clean

# Install NodeJS.
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo bash - \
 && apt-get -q update                                           \
 && apt-get -y -qq upgrade                                      \
 && apt-get -y -qq install                                      \
        nodejs build-essential                                  \
 && apt-get clean

# Install most-used libs
RUN set -xe; for package in \
      babel-core \
      babel-loader \
      babel-plugin-transform-runtime \
      babel-preset-es2015 \
      babel-preset-stage-0 \
      eslint \
      express \
      forever \
      mkdirp\
      npm \
      ncp \
      pm2 \
      rimraf \
      webpack \
      webpack-dev-server \
    ; do npm install -g $package; done

# Install PhantomJS
RUN apt-get install flex bison gperf ruby perl libsqlite3-dev libfontconfig1-dev libicu-dev libfreetype6 libssl-dev libpng-dev libjpeg-dev python libX11-dev libxext-dev git libfontconfig libjpeg-dev libicu-dev \
  && cd /tmp/ \
  && git clone https://github.com/Gomah/phantomjs-2.0.0-linux-armv7.git \
  && chmod +x phantomjs-2.0.0-linux-armv7/bin/phantomjs \
  && cp phantomjs-2.0.0-linux-armv7/bin/phantomjs /usr/bin \
  && rm -rf phantomjs-2.0.0-linux-armv7


# Install MongoDB
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		numactl \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

# pub   4096R/AAB2461C 2014-02-25 [expires: 2016-02-25]
#       Key fingerprint = DFFA 3DCF 326E 302C 4787  673A 01C4 E7FA AAB2 461C
# uid                  MongoDB 2.6 Release Signing Key <packaging@mongodb.com>
#
# pub   4096R/EA312927 2015-10-09 [expires: 2017-10-08]
#       Key fingerprint = 42F3 E95A 2C4F 0827 9C49  60AD D68F A50F EA31 2927
# uid                  MongoDB 3.2 Release Signing Key <packaging@mongodb.com>
#
ENV GPG_KEYS \
	DFFA3DCF326E302C4787673A01C4E7FAAAB2461C \
	42F3E95A2C4F08279C4960ADD68FA50FEA312927
RUN set -ex \
	&& for key in $GPG_KEYS; do \
		apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

ENV MONGO_MAJOR 3.2
ENV MONGO_VERSION 3.2.4

RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		mongodb-org=$MONGO_VERSION \
		mongodb-org-server=$MONGO_VERSION \
		mongodb-org-shell=$MONGO_VERSION \
		mongodb-org-mongos=$MONGO_VERSION \
		mongodb-org-tools=$MONGO_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 27017

# Define default command.
CMD ["node"]
CMD ["mongod"]
CMD ["phantomjs"]
