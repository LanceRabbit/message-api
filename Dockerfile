ARG APP_HOME=/app
ARG RUBY_VERSION=2.7.2

# Pre-compile Gems
FROM ruby:${RUBY_VERSION}-alpine AS builder

ARG APP_HOME
ENV APP_HOME=${APP_HOME}

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
# too many servies under apis folder that are nonuse in this project
# /usr/local/bundle/gems/google-api-client-0.44.0/generated/google/apis/
RUN gem install --no-document bundler:2.1.4 \
  && bundle config frozen 'true' \
  && bundle config no-cache 'true' \
  && bundle config set without 'build development test' \
  && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
  && find /usr/local/bundle -type f -name '*.c' -delete \
  && find /usr/local/bundle -type f -name '*.o' -delete \
  && find /usr/local/bundle -type d -name 'ext' -exec rm -rf {} + \
  && mv "$(bundle info google-api-client --path)/generated/google/apis/sheets_v4" "$(bundle info google-api-client --path)/generated/google/apis/sheets" \
  && mv "$(bundle info google-api-client --path)/generated/google/apis/sheets_v4.rb" "$(bundle info google-api-client --path)/generated/google/apis/sheets_rb" \
  && find "$(bundle info google-api-client --path)/generated/google/apis" -type d -name '*v*' -exec rm -rf {} + \
  && find "$(bundle info google-api-client --path)/generated/google/apis" -type f -name '*.rb' -not -path "$(bundle info google-api-client --path)/generated/google/apis/sheets/*" -delete \
  && mv "$(bundle info google-api-client --path)/generated/google/apis/sheets" "$(bundle info google-api-client --path)/generated/google/apis/sheets_v4" \
  && mv "$(bundle info google-api-client --path)/generated/google/apis/sheets_rb" "$(bundle info google-api-client --path)/generated/google/apis/sheets_v4.rb" \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && rm -rf /usr/local/bundle/specifications/*.gem

FROM ruby:${RUBY_VERSION}-alpine

ARG APP_HOME
ENV APP_HOME=${APP_HOME}

RUN adduser -h ${APP_HOME} -D -s /bin/nologin app app

# Setup Application
RUN mkdir -p $APP_HOME

COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config
COPY --from=builder /usr/local/bundle /usr/local/bundle
# COPY --chown=app:app --from=gem /${APP_HOME}/vendor/bundle /${APP_HOME}/vendor/bundle

# Add Source Files
COPY --chown=app:app . $APP_HOME

USER app
WORKDIR $APP_HOME

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]