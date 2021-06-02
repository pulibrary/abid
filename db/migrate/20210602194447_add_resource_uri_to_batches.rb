class AddResourceUriToBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :batches, :resource_uri, :string
  end
end
