class AddUniqueIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :absolute_identifiers, [:prefix, :suffix, :pool_identifier], unique: true, name: "absolute_identifiers_uniqueness"
  end
end
