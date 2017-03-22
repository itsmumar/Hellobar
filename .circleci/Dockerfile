FROM ruby:2.1.9

RUN apt-get update && curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -qq -y --no-install-recommends \
  build-essential git qt5-default libqt5webkit5-dev nodejs npm && \
  apt-get clean && \
  ln -s /usr/bin/nodejs /usr/bin/node && \
  rm -rf /var/lib/apt/lists/*

RUN gem install bundler && bundle config git.allow_insecure true && bundle config github.https true

RUN npm install -g ember-cli bower
