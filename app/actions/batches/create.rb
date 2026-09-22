# frozen_string_literal: true

module Abid
  module Actions
    module Batches
      # Ported from BatchesController#create.
      class Create < Abid::Action
        include Deps[view: "views.batches.index"]

        before :require_authorization

        def handle(request, response)
          batch = Batch.new(batch_params(request))
          batch.user = current_user(request)

          if batch.save
            response.redirect_to("/batches?created_batch=#{batch.id}")
          else
            # Rails re-rendered :index with the invalid batch still in @batch.
            client = Aspace::Client.new
            response.render(
              view,
              batch: batch,
              container_profiles: client.container_profiles,
              locations: client.locations,
              current_user: current_user(request)
            )
          end
        end

        private

        # params.require(:batch).permit(...)
        def batch_params(request)
          (request.params[:batch] || {}).slice(
            :call_number, :start_box, :end_box, :container_profile_uri,
            :location_uri, :first_barcode, :generate_abid
          )
        end
      end
    end
  end
end
