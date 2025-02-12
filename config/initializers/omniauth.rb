# frozen_string_literal: true
Rails.application.config.after_initialize do
  OmniAuth.config.allowed_request_methods = [:get]
end
