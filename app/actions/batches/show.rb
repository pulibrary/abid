# frozen_string_literal: true

module Abid
  module Actions
    module Batches
      # Ported from BatchesController#show. The Rails action had only a
      # `format.csv` block, so any other format raised UnknownFormat (406).
      class Show < Abid::Action
        before :require_authorization

        def handle(request, response)
          # Rails derived the response format from the .csv suffix and routed
          # :id without it. Hanami's :id captures the whole segment.
          batch = Batch.find(request.params[:id].to_s.sub(/\.csv\z/, ""))

          response.format = :csv
          response.headers["Content-Disposition"] = %(attachment; filename="batch-#{batch.id}.csv")
          response.body = batch.to_csv
        end
      end
    end
  end
end
