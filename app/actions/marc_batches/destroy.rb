# frozen_string_literal: true

module Abid
  module Actions
    module MarcBatches
      # Ported from MarcBatchesController#destroy.
      class Destroy < Abid::Action
        before :require_authorization

        def handle(request, response)
          batch = MarcBatch.find(request.params[:id])

          if batch.synchronized?
            response.flash[:alert] = "Unable to delete synchronized Batches."
          else
            batch.destroy
            response.flash[:notice] = "Deleted Batch #{batch.id}"
          end

          response.redirect_to("/batches")
        end
      end
    end
  end
end
