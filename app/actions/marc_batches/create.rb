# frozen_string_literal: true

module Abid
  module Actions
    module MarcBatches
      # Ported from MarcBatchesController#create.
      class Create < Abid::Action
        include Deps[view: "views.marc_batches.new"]

        before :build_sizes
        before :require_authorization

        def handle(request, response)
          batch = MarcBatch.new(batch_params(request))
          batch.user = current_user(request)

          if batch.save
            response.flash[:notice] = "Created MARC Batch"
            # NOTE: Rails redirected to batches_path, not marc_batches_path.
            response.redirect_to("/batches")
          else
            response.render(
              view,
              batch: batch,
              sizes: response[:sizes],
              current_user: current_user(request)
            )
          end
        end

        private

        def build_sizes(_request, response)
          response[:sizes] = ContainerProfile.select_labels("firestone")
        end

        # params.require(:marc_batch).permit(:prefix, :ignore_size_validation,
        #   absolute_identifiers_attributes: [:barcode, :prefix, :pool_identifier])
        def batch_params(request)
          params = request.params[:marc_batch] || {}
          permitted = params.slice(:prefix, :ignore_size_validation)
          nested = params[:absolute_identifiers_attributes]
          permitted[:absolute_identifiers_attributes] = permit_nested(nested) if nested
          permitted
        end

        # Rails accepted nested attributes either as an array or as a
        # hash keyed by index ("0", "1", ...), which is what the form posts.
        def permit_nested(nested)
          rows = nested.is_a?(Hash) ? nested.sort_by { |key, _| key.to_s.to_i }.map(&:last) : nested
          rows.map { |row| (row || {}).slice(:barcode, :prefix, :pool_identifier) }
        end
      end
    end
  end
end
