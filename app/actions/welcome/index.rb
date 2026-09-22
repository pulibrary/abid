# frozen_string_literal: true

module Abid
  module Actions
    module Welcome
      # Ported from WelcomeController#index:
      #
      #   redirect_to batches_path if current_user&.authorized?
      #
      # Note there is no before_action here: an unauthenticated or unauthorised
      # visitor falls through and renders the welcome page.
      class Index < Abid::Action
        include Deps[view: "views.welcome.index"]

        def handle(request, response)
          response.redirect_to("/batches") if current_user(request)&.authorized?

          response.render(view, current_user: current_user(request))
        end
      end
    end
  end
end
