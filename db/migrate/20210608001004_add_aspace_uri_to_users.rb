class AddAspaceUriToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :aspace_uri, :string
  end
end
