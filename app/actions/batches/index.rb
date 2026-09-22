# frozen_string_literal: true

module Abid
  module Actions
    module Batches
      # Ported from BatchesController#index.
      class Index < Abid::Action
        include Deps[view: "views.batches.index"]

        before :require_authorization

        def handle(request, response)
          client = Aspace::Client.new
          response.render(
            view,
            batch: new_batch(request),
            container_profiles: client.container_profiles,
            locations: client.locations,
            current_user: current_user(request)
          )
        end

        private

        # After a successful create the index pre-fills the form with the next
        # barcode in the reel, so the scanner operator can keep going.
        def new_batch(request)
          created_batch = request.params[:created_batch]
          return Batch.new unless created_batch

          batch = Batch.find(created_batch)
          new_barcode = BarcodeService.new(batch.barcodes.last).next(count: 1).last
          Batch.new(first_barcode: new_barcode)
        end
      end
    end
  end
end
