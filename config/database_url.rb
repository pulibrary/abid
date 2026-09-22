# frozen_string_literal: true

# Resolves DATABASE_URL, which is what hanami-db reads.
#
# The Rails app had two disjoint schemes in config/database.yml: development
# and test took host/port/user/password from environment variables that
# config/lando_env.rb injected by shelling out to `lando info`, while staging
# and production built a connection from APP_DB / APP_DB_HOST /
# APP_DB_USERNAME / APP_DB_PASSWORD (which is what both Nomad job specs set).
# Both are preserved here so neither the local workflow nor the deployed
# variable contract has to change.
require "json"

module Abid
  module DatabaseUrl
    class LandoPortUnavailable < StandardError; end

    LOCAL_DATABASE_NAMES = { "development" => "abid_development", "test" => "abid_test" }.freeze

    def self.call(env)
      return if present?(ENV.fetch("DATABASE_URL", nil))

      url = LOCAL_DATABASE_NAMES.key?(env) ? lando_url(env) : deployed_url
      ENV["DATABASE_URL"] = url if url
    end

    # Lando assigns the database a dynamic host port, so it has to be
    # discovered at boot.
    def self.lando_url(env)
      service = lando_services.find { |s| s[:service] == "abid_database" }
      return unless service

      connection = service[:external_connection] || {}
      credentials = service[:creds] || {}
      build(
        user: credentials[:user].to_s,
        password: credentials[:password].to_s,
        host: connection[:host] || "localhost",
        port: port_from(connection[:port]),
        database: LOCAL_DATABASE_NAMES.fetch(env)
      )
    end

    # `lando info` reports `"port": true` when the container is up but its
    # published port cannot be determined (for example when Docker's port
    # forwarding has wedged). Interpolating that produced
    # `postgres://...@127.0.0.1:true/abid_development` and a bare
    # URI::InvalidURIError several layers down, so fail here with something
    # a developer can act on.
    def self.port_from(value)
      port = Integer(value, exception: false)
      return port if port&.positive?

      raise LandoPortUnavailable, <<~MESSAGE
        `lando info` did not report a usable database port (got #{value.inspect}).

        The container is probably running but not reachable. Try:

          lando restart

        If that does not help, Docker's port forwarding may need restarting.
        You can also bypass lando discovery entirely by setting DATABASE_URL:

          DATABASE_URL=postgres://postgres@127.0.0.1:5432/abid_development
      MESSAGE
    end

    # Mirrors the staging/production block of the old database.yml, including
    # its defaults.
    def self.deployed_url
      build(
        user: ENV.fetch("APP_DB_USERNAME", "postgres"),
        password: ENV.fetch("APP_DB_PASSWORD", "postgres"),
        host: ENV.fetch("APP_DB_HOST", "localhost"),
        port: ENV.fetch("APP_DB_PORT", 5432),
        database: ENV.fetch("APP_DB", "abid")
      )
    end

    def self.build(user:, password:, host:, port:, database:)
      userinfo = password.to_s.empty? ? encode(user) : "#{encode(user)}:#{encode(password)}"
      "postgres://#{userinfo}@#{host}:#{port}/#{database}"
    end

    def self.encode(value) = value.to_s.gsub(/[^A-Za-z0-9\-._~]/) { |c| format("%%%02X", c.ord) }

    def self.present?(value) = !value.nil? && !value.empty?

    def self.lando_services
      JSON.parse(`lando info --format json`, symbolize_names: true)
    rescue StandardError
      []
    end
  end
end
