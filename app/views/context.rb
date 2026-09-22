# auto_register: false
# frozen_string_literal: true

require "vite_tags"
require "git_version"

module Abid
  module Views
    class Context < Hanami::View::Context
      # The layout renders these directly, as the Rails layout did via
      # vite_rails' helpers and the constants from config/initializers/git_sha.rb.
      def vite_client_tag = ViteTags.vite_client_tag
      def vite_javascript_tag(name) = ViteTags.vite_javascript_tag(name)

      def git_sha = ::GIT_SHA
      def branch = ::BRANCH
      def last_deployed = ::LAST_DEPLOYED

      # Available to the layout, which branches on it to pick the LUX menu.
      def current_user
        return @current_user if defined?(@current_user)

        @current_user =
          if request && (user_id = request.session[:user_id])
            User.find_by(id: user_id)
          end
      end

      def flash = request&.flash

      # @rails/ujs turns `data-method` / `data-confirm` links into real form
      # submissions, reading the token from these meta tags. Emitting
      # csrf-param as Hanami's parameter name makes UJS interoperate with
      # Hanami::Action::CSRFProtection unchanged.
      def csrf_meta_tags
        return "" unless request&.session

        token = request.session[:_csrf_token]
        [
          %(<meta name="csrf-param" content="_csrf_token" />),
          %(<meta name="csrf-token" content="#{token}" />)
        ].join("\n")
      end

      def csrf_token = request&.session&.[](:_csrf_token)
    end
  end
end
