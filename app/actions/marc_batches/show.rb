# frozen_string_literal: true

module Abid
  module Actions
    module MarcBatches
      # Ported from MarcBatchesController#show (CSV only, as in Rails).
      class Show < Abid::Action
        before :require_authorization

        def handle(request, response)
          # Rails derived the response format from the .csv suffix and routed
          # :id without it. Hanami's :id captures the whole segment.
          batch = MarcBatch.find(request.params[:id].to_s.sub(/\.csv\z/, ""))

          response.format = :csv
          response.headers["Content-Disposition"] = %(attachment; filename="batch-#{batch.id}.csv")
          response.body = batch.to_csv
        end
      end
    end
  end
end
