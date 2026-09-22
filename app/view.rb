# auto_register: false
# frozen_string_literal: true

require "hanami/view"

module Abid
  class View < Hanami::View
    config.layout = "app"
    config.default_context = Abid::Views::Context.new
  end
end
