# frozen_string_literal: true

module Abid
  module Actions
    module Sessions
      # GET /sign_in. This route was already broken in the Rails app: it
      # rendered Devise's packaged sessions/new template, which calls the
      # undefined `session_path` because User declared no
      # :database_authenticatable. Nothing links to it. Kept for route parity.
      class New < Abid::Action
        def handle(_request, _response)
          raise NoMethodError, "undefined local variable or method 'session_path'"
        end
      end
    end
  end
end
