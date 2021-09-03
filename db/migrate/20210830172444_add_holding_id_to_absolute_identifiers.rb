class AddHoldingIdToAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def change
    add_column :absolute_identifiers, :holding_id, :string
  end
end
