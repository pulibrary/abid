class AddLocationDataToBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :batches, :location_data, :jsonb
  end
end
