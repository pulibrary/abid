# frozen_string_literal: true
class AddUserIdToBatches < ActiveRecord::Migration[6.1]
  def change
    add_reference :batches, :user, foreign_key: true
  end
end
