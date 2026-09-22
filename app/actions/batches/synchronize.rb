# frozen_string_literal: true

module Abid
  module Actions
    module Batches
      # Ported from BatchesController#synchronize.
      class Synchronize < Abid::Action
        before :require_authorization

        def handle(request, response)
          batch = Batch.find(request.params[:id])
          batch.synchronize
          response.flash[:notice] = "Synchronized Batch #{batch.id}"
          response.redirect_to("/batches")
        end
      end
    end
  end
end
