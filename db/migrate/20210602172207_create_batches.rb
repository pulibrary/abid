# frozen_string_literal: true
class CreateBatches < ActiveRecord::Migration[6.1]
  def change
    create_table :batches do |t|
      t.integer :start_box
      t.integer :end_box
      t.string :first_barcode
      t.string :call_number
      t.string :location_uri
      t.string :container_profile_uri

      t.timestamps
    end
  end
end
