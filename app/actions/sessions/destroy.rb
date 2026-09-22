# frozen_string_literal: true

module Abid
  module Actions
    module Sessions
      # Ported from Devise::SessionsController#destroy, which was routed
      # directly as GET /sign_out and redirected to root_path.
      class Destroy < Abid::Action
        def handle(request, response)
          response.session[:user_id] = nil
          request.session.clear
          response.redirect_to("/")
        end
      end
    end
  end
end
