# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .tool-versions
# renovate: datasource=ruby-version depName=ruby
ARG RUBY_VERSION=4.0.6
FROM ruby:$RUBY_VERSION-slim AS base

# Hanami app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    HANAMI_ENV="production"


# Throw-away build stages to reduce size of final image
FROM base AS prebuild

# Install packages needed to build gems and node modules. `git` is required
# because the Gemfile sources archivesspace-client from GitHub (the released
# gem pins a stale dry-cli that conflicts with hanami-cli).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libffi-dev libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives


FROM prebuild AS node

# Install JavaScript dependencies
# renovate: datasource=node-version depName=node
ARG NODE_VERSION=24.19.0
# renovate: datasource=npm depName=yarn versioning=npm
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile


FROM prebuild AS build

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy node modules
COPY --from=node /app/node_modules /app/node_modules
COPY --from=node /usr/local/node /usr/local/node
ENV PATH=/usr/local/node/bin:$PATH

# Copy application code
COPY . .

# Stamp the build so the footer can render a version without shipping .git.
# config/initializers/git_sha.rb used to shell out to git at boot; lib/git_version.rb
# prefers these environment variables instead.
ARG GIT_SHA="Unknown SHA"
ARG BRANCH="Unknown branch"
ARG LAST_DEPLOYED="Not in deployed environment"
ENV GIT_SHA=$GIT_SHA BRANCH=$BRANCH LAST_DEPLOYED=$LAST_DEPLOYED

# Build the Vite bundle. Replaces `rails assets:precompile`, which ran both
# Sprockets and Vite; Sprockets is gone.
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec vite build


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y nginx && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# configure nginx
RUN gem install foreman && \
    sed -i 's|pid /run|pid /app/tmp/pids|' /etc/nginx/nginx.conf && \
    sed -i 's/access_log\s.*;/access_log \/dev\/stdout;/' /etc/nginx/nginx.conf && \
    sed -i 's/error_log\s.*;/error_log \/dev\/stderr info;/' /etc/nginx/nginx.conf

# NOTE: the /cable location block the Rails image carried is gone with
# ActionCable; nothing in this app uses websockets.
COPY <<-"EOF" /etc/nginx/sites-available/default
server {
  listen 3000 default_server;
  listen [::]:3000 default_server;
  access_log /dev/stdout;

  root /app/public;

  location / {
    try_files $uri @backend;
  }

  location @backend {
    proxy_pass http://localhost:3001;
    proxy_set_header Host $http_host;
  }
}
EOF

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /app /app

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 app && \
    useradd app --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp/pids public && \
    chown 1000:1000 /var/lib/nginx /var/log/nginx/* && \
    chown -R 1000:1000 log tmp public
USER 1000:1000

# Deployment options
ENV PORT="3001"

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Build a Procfile for production use
COPY <<-"EOF" /app/Procfile.prod
nginx: /usr/sbin/nginx -g "daemon off;"
web: bundle exec puma --port 3001 --environment production config.ru
EOF

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["foreman", "start", "--procfile=Procfile.prod"]
