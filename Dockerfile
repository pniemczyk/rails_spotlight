FROM ruby:2.6-alpine

RUN apk add --update --no-cache \
    build-base git openssh

RUN mkdir /app
WORKDIR /app

COPY Gemfile /app
COPY rails_spotlight.gemspec /app
COPY lib/rails_spotlight/version.rb /app/lib/rails_spotlight/version.rb
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"
RUN gem update --system 3.2.3
RUN gem install bundler -v 2.4.6
RUN bundle install

COPY . /app

RUN bundle install
CMD ["bundle", "exec", "rspec"]
