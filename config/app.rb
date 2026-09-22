# frozen_string_literal: true

require "hanami"
require "yaml"
require "erb"
require_relative "database_url"
require_relative "omniauth_middleware"

module Abid
  APP_ROOT = Pathname(__dir__).join("..").expand_path

  # Ported from config/initializers/abid_config.rb. Reads config/config.yml
  # through ERB, keyed by environment. Kept as a plain Hash rather than
  # `.with_indifferent_access`: every call site uses string keys, so the
  # ActiveSupport wrapper was never load-bearing. `Abid.config` is referenced
  # throughout the domain code and `Abid.all_environment_config` is called by
  # spec/support/stub_aspace.rb, so both names are preserved.
  def config
    @config ||= all_environment_config[env]
  end

  def all_environment_config
    @all_environment_config ||= YAML.safe_load(yaml, aliases: true)
  end

  def env
    (Hanami.respond_to?(:env) ? Hanami.env : ENV.fetch("HANAMI_ENV", "development")).to_s
  end

  private

  def yaml
    ERB.new(File.read(APP_ROOT.join("config", "config.yml"))).result
  end

  module_function :config, :yaml, :all_environment_config, :env

  # vite_ruby picks its mode from RAILS_ENV/RACK_ENV, neither of which exists
  # now. config/vite.json defines a "test" section (publicOutputDir
  # "vite-test"), so the mode has to be mapped from HANAMI_ENV to keep the
  # development and test builds separate, as they were under Rails.
  ENV["VITE_RUBY_MODE"] ||= env

  DatabaseUrl.call(env)

  class App < Hanami::App
    # Replaces Rails' ActionDispatch::Session::CookieStore. The Rails app used
    # the default cookie store with no session_store initializer; Warden wrote
    # the Devise user key into it. Here the session holds only :user_id.
    config.actions.sessions = :cookie, {
      key: "abid.session",
      secret: ENV.fetch("SECRET_KEY_BASE") { "development-secret-do-not-use-in-production" * 2 },
      expire_after: 60 * 60 * 24 * 30,
      secure: Hanami.env == :production,
      httponly: true
    }

    # The Rails app enforced NO Content-Security-Policy: every line of
    # config/initializers/content_security_policy.rb was commented out, and the
    # layout's csp_meta_tag therefore emitted nothing. Hanami ships a
    # restrictive default (script-src 'self'), which breaks the front end:
    # LUX/Vue uses the runtime template compiler, so mounting calls
    # `new Function(...)`, which CSP blocks. That exception aborts the whole
    # turbolinks:load handler, so BatchForm never initialises and the barcode
    # scanner's Enter key submits the form.
    #
    # Disabled here to match the Rails behaviour being ported. Adding a real
    # policy is worthwhile follow-up work, but it is a behaviour change and
    # would need `unsafe-eval` (or a build-time Vue template compile) to work.
    config.actions.content_security_policy = false

    # Rails served public/ itself in development and test
    # (config.public_file_server.enabled), and behind nginx in production,
    # which is how the Vite build output under public/vite-* reaches the
    # browser. Production keeps serving it through nginx, so this is dev/test
    # only unless RAILS_SERVE_STATIC_FILES-style behaviour is requested.
    if Hanami.env != :production || ENV["SERVE_STATIC_FILES"]
      require "rack/static"
      config.middleware.use(
        Rack::Static,
        # config/vite.json names the dev and test output dirs; production has
        # no section, so vite_ruby uses its default "vite".
        urls: ["/vite", "/vite-dev", "/vite-test"],
        root: "public"
      )
    end

    # OmniAuth is plain Rack middleware, so the CAS request phase
    # (GET /users/auth/cas) and the provider's redirect handling work exactly
    # as they did when Devise inserted this same strategy.
    config.middleware.use(
      Abid::OmniauthMiddleware,
      strategy: :cas,
      options: { host: "fed.princeton.edu", url: "https://fed.princeton.edu/cas" }
    )
  end
end
