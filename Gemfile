# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "alma"
gem "archivesspace-client"
gem "base64", "0.2.0" # To make the application bundle correctly
gem "bootsnap", ">= 1.4.4", require: false
gem "cocoon"
gem "csv", "~> 3.3.2"
gem "devise"
gem "health-monitor-rails", "12.6.0"
gem "honeybadger", "~> 5.0"
gem "jbuilder", "~> 2.7"
gem "marc"
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false
gem "net-ssh", "7.3.0"
gem "omniauth-cas"
gem "pg"
gem "puma", "~> 6.0"
gem "rails", "~> 7.2.0"
gem "rake"
gem "sass-rails", ">= 6"
gem "simple_form"
gem "turbolinks", "~> 5"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "vite_rails"

group :development, :test do
  gem "bixby"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
  gem "solargraph"
  gem "sqlite3"
end

group :development do
  # Annotate schema on to models automatically.
  gem "annotate"
  gem "bcrypt_pbkdf"
  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-passenger", require: false
  gem "capistrano-rails", "~> 1.4", require: false
  gem "capistrano-yarn", require: false
  gem "dockerfile-rails", ">= 1.7"
  gem "ed25519"
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 3.0"
  gem "spring"
  gem "web-console", ">= 4.1.0"
end

group :test do
  gem "capybara", "~> 3.37"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
