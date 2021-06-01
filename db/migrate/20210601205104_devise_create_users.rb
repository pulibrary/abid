# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      ## Rememberable
      t.datetime :remember_created_at

      ## Omniauthable
      t.string :provider, null: false, default: "cas"
      t.string :uid, null:false

      t.timestamps null: false
    end

    add_index :users, :uid, unique: true
    add_index :users, :provider
    add_index :users, [:uid,:provider], unique: true
  end
end
