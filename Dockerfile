FROM ruby:2.6.6-alpine3.12

ENV APP_HOME /app
ENV BUNDLE_FROZEN=true

WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock ./


RUN gem install bundler && bundle config set without 'test' &&bundle install

COPY . ./

# Run the web service on container startup.
# ENV PORT 4567
# EXPOSE 4567
CMD ["ruby", "./app.rb"]
# CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "4567"]