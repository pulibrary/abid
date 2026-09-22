# frozen_string_literal: true

require "form_builder"

module Abid
  module Views
    module Batches
      # Ported from app/views/batches/index.html.erb.
      #
      # Every exposure is undecorated: the templates work directly with the
      # domain objects (`batch.is_a?(MarcBatch)` in the batch table, the form
      # builder reading `batch.errors`), and a Hanami::View::Part wrapper
      # answers `class` and `is_a?` for itself rather than for the model.
      class Index < Abid::View
        expose :batch, decorate: false
        expose :container_profiles, default: [], decorate: false
        expose :locations, default: [], decorate: false
        expose :current_user, default: nil, decorate: false

        # `current_user&.unsynchronized_batches || []` from the Rails template.
        expose :unsynchronized_batches, decorate: false do |current_user: nil|
          current_user ? current_user.unsynchronized_batches : []
        end

        expose :synchronized_batches, decorate: false do |current_user: nil|
          current_user ? current_user.synchronized_batches : []
        end
      end
    end
  end
end
