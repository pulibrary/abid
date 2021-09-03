# frozen_string_literal: true
require_relative "abid_config"
Alma.configure do |config|
  config.apikey = Abid.config["alma_api_key"]
end
