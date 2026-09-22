# frozen_string_literal: true

# Ported from the Rails app's lib/tasks/servers.rake. Same three commands and
# the same lando workflow the README documents; `hanami db prepare` replaces
# `db:create` + `db:migrate`.
namespace :servers do
  desc "Create and migrate the development and test databases"
  task :initialize do
    sh "bundle exec hanami db prepare"
    sh "HANAMI_ENV=test bundle exec hanami db prepare"
  end

  desc "Starts development dependencies"
  task :start do
    sh "lando start"
    Rake::Task["servers:initialize"].invoke
  end

  desc "Stop development dependencies"
  task :stop do
    sh "lando stop"
  end
end
