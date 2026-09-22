# frozen_string_literal: true

module Abid
  module Actions
    module MarcBatches
      # Ported from MarcBatchesController#new.
      #
      # NOTE: in Rails, `before_action :build_sizes` was declared BEFORE
      # `before_action :require_authorization`, so the sizes were built even for
      # unauthorised visitors. The order is preserved here.
      class New < Abid::Action
        include Deps[view: "views.marc_batches.new"]

        before :build_sizes
        before :require_authorization

        def handle(request, response)
          batch = MarcBatch.new
          # @batch.absolute_identifiers.build — seeds one blank nested row.
          batch.absolute_identifiers_attributes = [{}]

          response.render(
            view,
            batch: batch,
            sizes: response[:sizes],
            current_user: current_user(request)
          )
        end

        private

        def build_sizes(_request, response)
          response[:sizes] = ContainerProfile.select_labels("firestone")
        end
      end
    end
  end
end
