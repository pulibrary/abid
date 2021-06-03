# frozen_string_literal: true
class AddBarcodeToAbsoluteIdentifier < ActiveRecord::Migration[6.1]
  def change
    add_column :absolute_identifiers, :barcode, :string
  end
end
