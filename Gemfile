# frozen_string_literal: true

source "https://rubygems.org", cooldown: 14
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# --- Hanami ---
# The 2.3 line is the newest *complete* stack: hanami-controller and
# hanami-validations have no 3.0 release yet, and hanami 3.0 requires
# hanami-utils ~> 3.0, which hanami-controller 2.3 cannot satisfy.
gem "hanami", "~> 2.3"
gem "hanami-controller", "~> 2.3"
gem "hanami-db", "~> 2.3"
gem "hanami-router", "~> 2.3"
gem "hanami-validations", "~> 2.3"
gem "hanami-view", "~> 2.3"

gem "dry-monads", "~> 1.6"
gem "dry-operation", ">= 1.0.1"
gem "dry-types", "~> 1.7"

# --- Application dependencies carried over from the Rails app ---
gem "alma"
# Same 0.6.0 code as the released gem; only the gemspec differs, relaxing a stale
# `dry-cli ~> 0.7` pin that conflicts with hanami-cli's `dry-cli ~> 1.0`.
gem "archivesspace-client", github: "lyrasis/archivesspace-client"
gem "base64", "0.3.0"
gem "csv", "~> 3.3.2"
gem "honeybadger", "6.9.1"
gem "httparty" # transitive via alma/archivesspace-client; pinned here as it is used directly
gem "marc"
gem "omniauth-cas"
gem "pg"
gem "puma", "~> 8.0"
gem "rake"
# Named-timezone data for HoneybadgerCheck's America/New_York maintenance
# window. Ruby has no stdlib equivalent; this is the same zone data
# ActiveSupport::TimeZone wrapped, so the arithmetic is unchanged. Declared
# explicitly rather than relied on transitively via activesupport.
gem "tzinfo"
gem "vite_ruby"

group :development, :test do
  gem "benchmark" # no longer a default gem on Ruby 4.0; required by rubocop
  gem "bixby"
  gem "dotenv"
  gem "factory_bot"
  gem "pry-byebug"
  gem "rspec"
end

group :development do
  gem "hanami-reloader", "~> 2.3"
  gem "hanami-webconsole", "~> 2.3"
end

group :test do
  gem "capybara", "~> 3.37"
  gem "rack-test"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
