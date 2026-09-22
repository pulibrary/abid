# frozen_string_literal: true

module Abid
  module Actions
    module MarcBatches
      # Ported from MarcBatchesController#synchronize.
      class Synchronize < Abid::Action
        before :require_authorization

        def handle(request, response)
          batch = MarcBatch.find(request.params[:id])
          batch.synchronize
          response.flash[:notice] = "Synchronized MARC Batch #{batch.id}"
          response.redirect_to("/batches")
        end
      end
    end
  end
end
