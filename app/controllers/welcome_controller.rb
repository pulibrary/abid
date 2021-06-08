# frozen_string_literal: true
class WelcomeController < ApplicationController
  def index
    if current_user
      redirect_to batches_path
    end
  end
end
