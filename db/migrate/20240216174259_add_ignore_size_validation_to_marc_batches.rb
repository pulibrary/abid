class AddIgnoreSizeValidationToMarcBatches < ActiveRecord::Migration[7.1]
  def change
    add_column :marc_batches, :ignore_size_validation, :boolean, default: false
  end
end
