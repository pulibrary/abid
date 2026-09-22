# frozen_string_literal: true

module Abid
  module Relations
    class MarcBatches < Abid::DB::Relation
      schema :marc_batches, infer: true
    end
  end
end
