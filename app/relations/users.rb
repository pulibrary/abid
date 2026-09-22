# frozen_string_literal: true

module Abid
  module Relations
    class Users < Abid::DB::Relation
      schema :users, infer: true
    end
  end
end
