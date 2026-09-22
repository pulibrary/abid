# frozen_string_literal: true

# Ported from config/initializers/alma.rb. Registers nothing, on purpose: as
# under Rails this is a global side effect on the `alma` gem's singleton
# configuration, which Alma::BibHolding reads at call time.
Hanami.app.register_provider(:alma) do
  prepare do
    require "alma"
  end

  start do
    Alma.configure do |config|
      config.apikey = Abid.config["alma_api_key"]
      config.timeout = 120
    end
  end
end
