FROM ruby:2.3.4

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
    build-essential git qt5-default libqt5webkit5-dev nodejs npm \
    xvfb xauth gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -qq -y --no-install-recommends yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler && bundle config git.allow_insecure true && bundle config github.https true

RUN yarn global add ember-cli bower
