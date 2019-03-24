FROM alpine

WORKDIR /uat-ask
ENV RAILS_ENV=production
ENV BOT_TOKEN="" 
ENV GATEKEEPER="" 
ENV ADMINS=[""] 
ENV SLACK_DOMAIN="" 
ENV HOST="" 
ENV DB_NAME="" 
ENV DB_USER="" 
ENV DB_PASS=""
ENV SECRET_KEY_BASE=""

RUN apk update && apk add --no-cache \
	ca-certificates \
    tzdata \
    mariadb-client-libs \
    freetds \
    nodejs \
    mysql-client \
    git  \
    curl \
    file \
    yarn \
    bash \ 
    libxml2-dev libxslt-dev freetds-dev alpine-sdk mariadb-dev


COPY Gemfile* /uat-ask/

RUN apk add --no-cache alpine-sdk mariadb-dev && \
	gem install bundler && \
    bundle pack && \
    bundle install --jobs=4 --without development test --clean

COPY . /uat-ask

RUN bundle exec rake assets:precompile


EXPOSE 3000
ENTRYPOINT ["bundle", "exec", "rails", "db:create", "db:migrate", "start_server"]