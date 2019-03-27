FROM ruby:2.5-alpine3.8

WORKDIR /uat-env-gatekeeper

RUN apk update && \
    apk add --no-cache \
        ca-certificates \
	    tzdata \
        curl \
	    mysql-client 

RUN gem update --system && gem install bundler

ENV RAILS_ENV=production
ENV BOT_TOKEN="xoxb-339394118256-w8CgMu7Fv4TWwqgcvjcQwoSl" 
ENV GATEKEEPER="U04M7SLEN" 
ENV ADMINS=["U04M7SLEN"] 
ENV SLACK_DOMAIN="wyzant" 
ENV HOST="db" 
ENV DB_USER="root" 
ENV DB_PASS=""
ENV SECRET_KEY_BASE="9dd4e2f0176a774cf426c773572c421d92f979e1be7bfb3434ffb65203862cc9f49d45e11001e641f8f69f0fb827e91c82d461d768aee606cebd44afa17f88e4"

RUN apk add --no-cache \
        nodejs \
        git  \
        file \
        yarn \
        bash \ 
        libxml2-dev \
        libxslt-dev \
        freetds-dev \
        alpine-sdk \
        mariadb-dev

COPY Gemfile* /uat-env-gatekeeper/

RUN bundle install --jobs=4 --without development test

COPY . /uat-env-gatekeeper

RUN bundle exec rake assets:precompile

EXPOSE 3000
ENTRYPOINT ["bundle", "exec", "rails", "db:create", "db:migrate", "start_server"]