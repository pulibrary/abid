# frozen_string_literal: true

require "rack/test"

# Replaces the Warden/Devise-based helper of the same name. The point of this
# file is that spec EXAMPLES do not change: `sign_in user`, `get "/batches"`,
# `response`, `flash.alert` and `redirect_to batches_path` all keep working.
module RequestSpecHelper
  include Rack::Test::Methods

  def app = Hanami.app

  # Rails' integration specs exposed the response as `response`.
  def response = last_response

  # Drives the real CAS callback through OmniAuth's test mode, so signing in
  # exercises the same code path the application uses in production. Replaces
  # Devise::Test::IntegrationHelpers#sign_in.
  def sign_in(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:cas] = OmniAuth::AuthHash.new(
      provider: user.provider, uid: user.uid
    )
    get "/users/auth/cas/callback"
    follow_redirect! while last_response.redirect?
    user
  end

  def sign_out
    get "/sign_out"
  end

  # Rails exposed flash on the integration session. Only `.alert` and `.notice`
  # are read by the specs.
  def flash = FlashProxy.new(last_request)

  class FlashProxy
    def initialize(request) = @request = request
    def [](key) = flash_hash[key] || flash_hash[key.to_s]
    def alert = self[:alert]
    def notice = self[:notice]

    private

    def flash_hash
      @request.session["_flash"] || @request.env["rack.session"]&.[]("_flash") || {}
    rescue StandardError
      {}
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :request
  config.include RequestSpecHelper, type: :request
  config.include RequestSpecHelper, type: :controller
end
