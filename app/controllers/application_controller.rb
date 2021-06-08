# frozen_string_literal: true
class ApplicationController < ActionController::Base
  def require_authorization
    redirect_to root_path unless current_user&.authorized?
  end
end
