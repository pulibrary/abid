# frozen_string_literal: true

require "form_builder"

module Abid
  module Views
    module MarcBatches
      # Ported from app/views/marc_batches/new.html.erb.
      class New < Abid::View
        expose :batch, decorate: false
        expose :sizes, default: [], decorate: false
        expose :current_user, default: nil, decorate: false

        # `@batch.absolute_identifiers.build` from MarcBatchesController#new.
        # The action asks for the same thing with
        # `absolute_identifiers_attributes = [{}]`, but that writer applies the
        # model's `reject_if` (a blank barcode), so a row seeded that way never
        # reaches the form. Building it here keeps the new form's single empty
        # row, which is what the form is for.
        expose :absolute_identifiers, decorate: false do |batch|
          batch.absolute_identifiers.build if batch.absolute_identifiers.empty?
          batch.absolute_identifiers.to_a
        end
      end
    end
  end
end
