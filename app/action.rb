# auto_register: false
# frozen_string_literal: true

require "hanami/action"

module Abid
  class Action < Hanami::Action
    # Hanami actions are instantiated once and shared across requests, so
    # per-request state must never be memoised on the instance. current_user is
    # cached in the Rack env for the life of the request instead.
    CURRENT_USER_KEY = "abid.current_user"

    private

    def current_user(request)
      return request.env[CURRENT_USER_KEY] if request.env.key?(CURRENT_USER_KEY)

      user_id = request.session[:user_id]
      request.env[CURRENT_USER_KEY] = user_id ? User.find_by(id: user_id) : nil
    end

    # Ported from ApplicationController#require_authorization:
    #
    #   redirect_to root_path unless current_user&.authorized?
    #
    # `authorized?` performs an ArchivesSpace round trip on every request, as
    # it did under Rails. `redirect_to` halts, so this stops the action.
    def require_authorization(request, response)
      response.redirect_to("/") unless current_user(request)&.authorized?
    end
  end
end
