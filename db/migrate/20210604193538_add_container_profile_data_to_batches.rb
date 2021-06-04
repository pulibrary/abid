class AddContainerProfileDataToBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :batches, :container_profile_data, :jsonb
  end
end
