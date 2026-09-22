# frozen_string_literal: true

module Abid
  module Relations
    class Batches < Abid::DB::Relation
      schema :batches, infer: true
    end
  end
end
