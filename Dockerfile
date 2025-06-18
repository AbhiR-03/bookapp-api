
FROM ruby:3.0.2 AS build

RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev git curl libssl-dev \
  libreadline-dev zlib1g-dev nodejs postgresql-client yarn

WORKDIR /app

# 💡 Only copy Gemfile and lock first to leverage Docker layer caching
COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.3.5
# 💡 Install gems to a fixed path to copy them later
RUN bundle config set path 'vendor/bundle' && bundle install

# 🔁 Now copy the rest of the app code
COPY . .

#####################

FROM ruby:3.0.2-slim

RUN apt-get update -qq && apt-get install -y \
  libpq-dev nodejs yarn && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 🧠 Copy app and installed gems
COPY --from=build /app /app

# ✅ Ensure gems are on the PATH
ENV BUNDLE_PATH=/app/vendor/bundle
ENV PATH="/app/bin:/app/vendor/bundle/bin:$PATH"

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

