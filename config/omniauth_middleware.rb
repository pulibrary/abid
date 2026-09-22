# frozen_string_literal: true

require "omniauth"
require "omniauth-cas"

module Abid
  # Wraps OmniAuth::Builder so the CAS strategy can be added to Hanami's
  # middleware stack. Ported from `config.omniauth :cas, ...` in
  # config/initializers/devise.rb plus config/initializers/omniauth.rb.
  #
  # `allowed_request_methods = [:get]` is what makes the plain
  # `<a href="/users/auth/cas">` links in the layout work; OmniAuth 2 is
  # POST-only by default. The Rails app set this and configured no request-phase
  # CSRF protection, so neither does this.
  OmniAuth.config.allowed_request_methods = [:get]
  OmniAuth.config.path_prefix = "/users/auth"
  OmniAuth.config.logger = Logger.new(IO::NULL) if ENV["HANAMI_ENV"] == "test"

  class OmniauthMiddleware
    def initialize(app, strategy:, options: {})
      @app = OmniAuth::Builder.new(app) do
        provider strategy, **options
      end
    end

    def call(env) = @app.call(env)
  end
end
