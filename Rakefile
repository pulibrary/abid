# frozen_string_literal: true

require "hanami/rake_tasks"

# Rails provided an `:environment` task that booted the app, and the tasks in
# lib/tasks depend on it. Hanami has no equivalent, so it is defined here and
# the task files are left as they were.
desc "Boot the application (compatibility shim for the Rails :environment task)"
task :environment do
  require "hanami/boot"
end

# Add your custom rake tasks to the lib/tasks directory
Rake.add_rakelib "lib/tasks"
