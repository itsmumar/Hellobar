FROM hellobarcom/base:2.3.4

ENV DISPLAY :99
ENV APP /app/
RUN mkdir -p $APP
WORKDIR $APP

COPY Gemfile* $APP
RUN bundle install

COPY . $APP

RUN cd editor && yarn install --cache-folder .yarn --frozen-lockfile
RUN cd editor && bower install --allow-root
RUN cd editor && ember build --environment=production

EXPOSE 3000
CMD ['thin', 'start']
