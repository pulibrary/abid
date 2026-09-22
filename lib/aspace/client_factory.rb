# frozen_string_literal: true

require "aspace/client"

module Aspace
  # `Aspace::Client#initialize` performs an HTTP login, and the Rails app built
  # a brand new (freshly logged-in) client at each of its five call sites
  # rather than sharing one. Registering a client *instance* in the container
  # would change that twice over: it would log in during boot (breaking the
  # `hanami db ...` CLI and every spec) and it would share one session across
  # all call sites.
  #
  # So "aspace.client" is registered as this factory instead. Resolving it does
  # no I/O; `#new` (or its `#call` alias) yields a fresh, logged-in client
  # exactly where the old code said `Aspace::Client.new`.
  class ClientFactory
    def new
      Client.new
    end
    alias call new
  end
end
