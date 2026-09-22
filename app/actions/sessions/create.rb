# frozen_string_literal: true

module Abid
  module Actions
    module Sessions
      # Ported from Users::OmniauthCallbacksController#cas.
      #
      # The Rails original read:
      #
      #   if @user.nil?
      #     redirect_to root_path
      #     flash[:error] = "You are not authorized"
      #   else
      #     sign_in_and_redirect @user, event: :authentication
      #     set_flash_message(:success, :success, kind: "from Princeton ...")
      #   end
      #
      # Rails' redirect_to does not halt, so the flash assignment after it still
      # took effect. Hanami's redirect_to DOES halt, so both flashes are set
      # before redirecting. Observable behaviour is unchanged.
      class Create < Abid::Action
        def handle(request, response)
          user = ::User.from_cas(request.env["omniauth.auth"])

          if user.nil?
            response.flash[:error] = "You are not authorized"
          else
            response.session[:user_id] = user.id
            # Devise's set_flash_message interpolated kind: "from Princeton
            # Central Authentication Service" into "Successfully authenticated
            # from %{kind} account.", producing a doubled "from from". Preserved
            # verbatim: the omniauth callbacks spec asserts this exact string.
            response.flash[:success] =
              "Successfully authenticated from from Princeton Central Authentication Service account."
          end

          # Devise's after_sign_in_path_for fell through to root_path, and the
          # nil-user branch redirected to root_path too.
          response.redirect_to("/")
        end
      end
    end
  end
end
