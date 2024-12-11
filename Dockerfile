FROM ubuntu:20.04

ENV RAILS_ENV="development"
ENV GEM_HOME=/app/.gem
ENV BUNDLE_PATH=/app/.bundle
ENV PATH="/app/.gem/bin:/app/ruby/bin:$PATH"

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV RUBYOPT="-E utf-8"
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York

# Install dependencies and required packages for Ruby and PostgreSQL
RUN apt-get update && \
  apt-get install -y \
  --no-install-recommends \
  git curl build-essential ca-certificates \
  libssl-dev libreadline-dev zlib1g-dev \
  bison libyaml-dev libgdbm-dev libffi-dev \
  libpq-dev tzdata \
  && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install ruby-install, install Ruby, and configure gem options
RUN git clone https://github.com/postmodern/ruby-install.git && \
  cd ruby-install && \
  make install && \
  CONFIGURE_OPTS=--disable-install-doc ruby-install --install-dir /app/ruby ruby 3.2.2 && \
  echo "gem: --no-document" > /root/.gemrc && \
  cd .. && \
  rm -rf ruby-install

# Set up the deploy user and directories
RUN useradd -d /app -m -s /bin/bash deploy && \
  mkdir -p /app/www && \
  chown deploy:deploy /app /app/www && \
  chmod -R 755 /app

USER deploy

# Copy the Gemfile and install the gems
COPY --chown=deploy:deploy Gemfile* /app/www/
COPY --chown=deploy:deploy ./vendor /app/www/vendor
COPY --chown=deploy:deploy . /app/www/

# Install bundler and the application dependencies
RUN cd /app/www && \
  gem install bundler -v '2.5.23' && \
  bundle install

# Set the working directory
WORKDIR /app/www

# Expose port for the Rails app
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
