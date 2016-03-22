FROM ruby:2.1

ENV APP=hellobar

RUN mkdir -p /docker/$APP
WORKDIR /docker/$APP

RUN apt-get update && \
    apt-get install -y qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x \
                       nodejs mysql-client  --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_JOBS=2 \
    BUNDLE_PATH=/bundle

COPY Gemfile* /docker/$APP/
RUN bundle install

COPY . /docker/$APP

EXPOSE 3000
CMD ["thin", "start"]
