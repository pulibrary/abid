# frozen_string_literal: true
class AddGenerateAbidToAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def change
    add_column :batches, :generate_abid, :boolean, default: true
  end
end
