# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

gem "alma"
gem "archivesspace-client"
gem "bcrypt_pbkdf"
gem "bootsnap", ">= 1.4.4", require: false
gem "cocoon"
gem "devise"
gem "ed25519"
gem "honeybadger", "~> 4.0"
gem "jbuilder", "~> 2.7"
gem "marc"
gem "omniauth-cas"
gem "pg"
gem "puma", "~> 5.0"
gem "rails", "~> 7.0.0"
gem "rake"
gem "sass-rails", ">= 6"
gem "simple_form"
gem "turbolinks", "~> 5"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "webpacker", "~> 5.0"

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
  gem "ed25519"
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"
  gem "spring"
  gem "web-console", ">= 4.1.0"
end

group :test do
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webdrivers"
  gem "webmock"
end
