# frozen_string_literal: true

# "aspace.client" is registered as a FACTORY, not as a connected client.
#
# `Aspace::Client#initialize` calls `login`, an HTTP round trip. The Rails app
# built a brand new client at each of its five call sites, so each one logged
# in separately. Registering an instance here would both log in at boot (which
# would break the `hanami db ...` CLI commands and every spec) and share a
# single session across call sites. Neither matches the old behaviour.
#
# Resolving this key therefore does no I/O. Call sites that used to say
# `Aspace::Client.new` say `Hanami.app["aspace.client"].new` (`.call` is an
# alias) and get a fresh, logged-in client at exactly the same moment as before.
Hanami.app.register_provider(:aspace) do
  prepare do
    require "aspace/client_factory"
  end

  start do
    register "aspace.client", Aspace::ClientFactory.new
  end
end
