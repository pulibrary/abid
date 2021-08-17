class AddBatchTypeToAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def change
    add_column :absolute_identifiers, :batch_type, :string, default: "Batch"
  end
end
