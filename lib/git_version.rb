# frozen_string_literal: true

require "date"

# Ported from config/initializers/git_sha.rb, which defined three global
# constants the layout renders. Behaviour is unchanged, including the
# Capistrano-era revisions.log path and the shelling out to git in
# development/test. ENV overrides are honoured first so a container image can
# be stamped at build time rather than shipping a .git directory.
#
# The original was a flat sequence of conditionals at the top of an initializer.
# It is expressed as methods here so each branch can actually be exercised;
# config/ was filtered out of coverage under Rails, lib/ is not.
module GitVersion
  module_function

  def revisions_logfile = Abid::APP_ROOT.join("..", "..", "revisions.log")

  def deployed? = File.exist?(revisions_logfile)

  def development_or_test? = %w[development test].include?(Abid.env)

  def revisions_log_line = `tail -1 #{revisions_logfile}`.chomp

  def env_override(key)
    value = ENV.fetch(key, nil)
    value unless value.nil? || value.empty?
  end

  def sha
    env_override("GIT_SHA") ||
      if deployed?
        revisions_log_line.split(" ")[3].gsub(/\)$/, "")
      elsif development_or_test?
        `git rev-parse HEAD`.chomp
      else
        "Unknown SHA"
      end
  end

  def branch
    env_override("BRANCH") ||
      if deployed?
        revisions_log_line.split(" ")[1]
      elsif development_or_test?
        `git rev-parse --abbrev-ref HEAD`.chomp
      else
        "Unknown branch"
      end
  end

  def last_deployed
    env_override("LAST_DEPLOYED") ||
      if deployed?
        Date.parse(revisions_log_line.split(" ")[7]).strftime("%d %B %Y")
      else
        "Not in deployed environment"
      end
  end
end

# The layout reads these as constants, as it did under Rails.
GIT_SHA = GitVersion.sha
BRANCH = GitVersion.branch
LAST_DEPLOYED = GitVersion.last_deployed
