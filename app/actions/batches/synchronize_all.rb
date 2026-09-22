# frozen_string_literal: true

module Abid
  module Actions
    module Batches
      # Ported from BatchesController#synchronize_all.
      class SynchronizeAll < Abid::Action
        before :require_authorization

        def handle(request, response)
          current_user(request).unsynchronized_batches.each(&:synchronize)
          response.flash[:notice] = "Synchronized all unsynchronized batches"
          response.redirect_to("/batches")
        end
      end
    end
  end
end
