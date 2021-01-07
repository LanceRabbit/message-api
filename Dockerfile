FROM ruby:2.7.2-alpine

ENV APP_HOME /app
ENV BUNDLE_FROZEN=true

WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock ./

RUN gem install --no-document bundler && bundle config set without 'development test' && bundle install

COPY . ./

# Run the web service on container startup.
# ENV PORT 4567
# EXPOSE 4567
CMD ["ruby", "./app.rb"]
# CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "4567"]
