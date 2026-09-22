# frozen_string_literal: true

module Abid
  module Relations
    class AbsoluteIdentifiers < Abid::DB::Relation
      schema :absolute_identifiers, infer: true
    end
  end
end
