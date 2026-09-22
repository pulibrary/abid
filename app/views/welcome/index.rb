# frozen_string_literal: true

module Abid
  module Views
    module Welcome
      class Index < Abid::View
        expose :current_user, default: nil
      end
    end
  end
end
