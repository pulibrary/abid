# frozen_string_literal: true

require "omniauth"

# Rails controller specs bypassed the Rack middleware stack entirely, so
# hitting the callback action needed no CAS ticket. Hanami request specs go
# through the real stack, where OmniAuth would bounce a ticketless callback to
# /users/auth/failure. Test mode makes the middleware short-circuit and inject
# a mock auth hash, which is the documented way to exercise the callback.
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:cas] = OmniAuth::AuthHash.new(provider: "cas", uid: "user")

RSpec.configure do |config|
  config.before do
    OmniAuth.config.mock_auth[:cas] = OmniAuth::AuthHash.new(provider: "cas", uid: "user")
  end
end
