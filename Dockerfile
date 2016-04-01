FROM buildpack-deps:precise

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.8
ENV RUBY_DOWNLOAD_SHA256 afd832b8d5ecb2e3e1477ec6a9408fdf9898ee73e4c5df17a2b2cb36bd1c355d
ENV RUBYGEMS_VERSION 2.6.2

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
  && buildDeps=' \
    bison \
    libgdbm-dev \
    ruby \
  ' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/ruby \
  && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.gz \
  && cd /usr/src/ruby \
  && { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
  && autoconf \
  && ./configure --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y --auto-remove $buildDeps \
  && gem update --system $RUBYGEMS_VERSION \
  && rm -r /usr/src/ruby

ENV BUNDLER_VERSION 1.11.2

RUN gem install bundler --version "$BUNDLER_VERSION"

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME" \
  BUNDLE_JOBS=8
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN apt-get update \
 && apt-get -y install python-software-properties software-properties-common \
 && apt-add-repository ppa:ubuntu-sdk-team/ppa \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
     qtdeclarative5-dev qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x \
     nodejs mysql-client \
     sudo \
 && rm -rf /var/lib/apt/lists/*

ARG APP=app

RUN useradd --shell /bin/bash --create-home $APP \
 && gpasswd -a $APP $APP \
 && echo "$APP ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir -p /docker/$APP && chown -R $APP:$APP /docker/$APP
WORKDIR /docker/$APP

USER $APP

COPY Gemfile* /docker/$APP/
RUN bundle install

COPY . /docker/$APP

EXPOSE 3000
CMD ["thin", "start"]
