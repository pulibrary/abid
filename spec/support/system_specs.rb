# frozen_string_literal: true

require "capybara"
require "capybara/rspec"
require "selenium-webdriver"

Capybara.app = Hanami.app

# rails-controlled Capybara registered its rack_test driver with
# respect_data_method: true, so `link_to ..., method: :post` and
# `data: {confirm:}` links worked without JavaScript. The stock Capybara
# driver ignores data-method and issues a GET, which the router answers with
# 405. The batch table still uses those links (@rails/ujs handles them in the
# browser), so the driver has to respect them here too.
Capybara.register_driver(:rack_test) do |app|
  Capybara::RackTest::Driver.new(app, respect_data_method: true)
end
Capybara.server = :puma, { Silent: true }

Capybara.register_driver(:selenium_chrome_headless) do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1400,1400")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver(:selenium_chrome) do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

# Rails' system tests provided `driven_by`. Reimplemented so the driver
# selection below (copied unchanged from the Rails app) still works.
module SystemSpecHelper
  def driven_by(driver) = Capybara.current_driver = driver
end

RSpec.configure do |config|
  config.include SystemSpecHelper, type: :system
  config.include Capybara::DSL, type: :system
  config.include Capybara::RSpecMatchers, type: :system

  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.before(:each, type: :system, js: true) do
    if ENV["RUN_IN_BROWSER"]
      driven_by(:selenium_chrome)
    else
      driven_by(:selenium_chrome_headless)
    end
  end
  config.before(:each, type: :system, js: true, in_browser: true) do
    driven_by(:selenium_chrome)
  end

  config.after(:each, type: :system) do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

# Capybara-driven equivalent of RequestSpecHelper#sign_in, so system specs use
# the same `sign_in user` call the Rails app's Devise helper provided.
module SystemSessionHelper
  def sign_in(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:cas] = OmniAuth::AuthHash.new(
      provider: user.provider, uid: user.uid
    )
    visit "/users/auth/cas/callback"
    user
  end

  def sign_out
    visit "/sign_out"
  end
end

RSpec.configure do |config|
  config.include SystemSessionHelper, type: :system
end
