class CreateMarcBatches < ActiveRecord::Migration[6.1]
  def change
    create_table :marc_batches do |t|
      t.timestamps
    end
  end
end
