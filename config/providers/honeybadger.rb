# frozen_string_literal: true

# The `Honeybadger.configure` half of the old
# config/initializers/honeybadger_downtime_hook.rb. The HoneybadgerCheck class
# itself now lives in lib/honeybadger_check.rb so that spec/honeybadger_check_spec.rb
# can load it without triggering this side effect.
#
# Registers nothing, on purpose: Honeybadger's configuration is a global
# singleton, exactly as it was under Rails.
Hanami.app.register_provider(:honeybadger) do
  prepare do
    require "honeybadger"
    require "honeybadger_check"
  end

  start do
    Honeybadger.configure do |config|
      config.before_notify do |notice|
        # Add a maintenance_window tag - tags seems to be a comma delimited string,
        # so split them, add the maintenance_window one, and rejoin them.
        notice.context[:maintenance_window] = "true" if HoneybadgerCheck.maintenance_window?
      end
    end
  end
end
