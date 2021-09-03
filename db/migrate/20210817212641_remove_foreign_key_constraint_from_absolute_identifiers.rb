class RemoveForeignKeyConstraintFromAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def change
    if foreign_key_exists?(:absolute_identifiers, :batches)
      remove_foreign_key :absolute_identifiers, :batches
    end
  end
end
