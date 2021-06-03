class CreateAbsoluteIdentifiers < ActiveRecord::Migration[6.1]
  def change
    create_table :absolute_identifiers do |t|
      t.integer :original_box_number
      t.string :top_container_uri
      t.integer :batch_id
      t.string :prefix
      t.string :suffix
      t.string :sync_status
      t.string :pool_identifier

      t.timestamps
    end
  end
end
