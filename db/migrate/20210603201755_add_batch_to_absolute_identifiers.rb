# frozen_string_literal: true
class AddBatchToAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def up
    remove_column :absolute_identifiers, :batch_id
    add_reference :absolute_identifiers, :batch, foreign_key: true
  end

  def down
    remove_reference :absolute_identifiers, :batch, foreign_key: true
    add_column :absolute_identifiers, :batch_id, :integer
  end
end
