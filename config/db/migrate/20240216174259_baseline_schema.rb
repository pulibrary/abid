# frozen_string_literal: true

# Baseline of the schema as it stood at the end of the Rails app
# (db/schema.rb, version 2024_02_16_174259). Column types, defaults, nullability
# and indexes are reproduced exactly: the Hanami app runs against the existing
# production database, so this must not drift from what Rails created.
ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id, type: :Bignum, serial: true, identity: false
      column :aspace_uri, "character varying"
      column :created_at, "timestamp(6) without time zone", null: false
      column :provider, "character varying", default: "cas", null: false
      column :remember_created_at, "timestamp without time zone" # precision: nil
      column :uid, "character varying", null: false
      column :updated_at, "timestamp(6) without time zone", null: false

      index [:provider], name: :index_users_on_provider
      index [:uid], name: :index_users_on_uid, unique: true
      index %i[uid provider], name: :index_users_on_uid_and_provider, unique: true
    end

    create_table :batches do
      primary_key :id, type: :Bignum, serial: true, identity: false
      column :call_number, "character varying"
      column :container_profile_data, :jsonb
      column :container_profile_uri, "character varying"
      column :created_at, "timestamp(6) without time zone", null: false
      column :end_box, Integer
      column :first_barcode, "character varying"
      column :generate_abid, TrueClass, default: true
      column :location_data, :jsonb
      column :location_uri, "character varying"
      column :resource_uri, "character varying"
      column :start_box, Integer
      column :updated_at, "timestamp(6) without time zone", null: false
      foreign_key :user_id, :users, type: :Bignum, foreign_key_constraint_name: :fk_rails_ae06cb64ba

      index [:user_id], name: :index_batches_on_user_id
    end

    create_table :marc_batches do
      primary_key :id, type: :Bignum, serial: true, identity: false
      column :created_at, "timestamp(6) without time zone", null: false
      column :ignore_size_validation, TrueClass, default: false
      column :updated_at, "timestamp(6) without time zone", null: false
      foreign_key :user_id, :users, type: :Bignum, null: false,
                  foreign_key_constraint_name: :fk_rails_5bd1f9ffcf

      index [:user_id], name: :index_marc_batches_on_user_id
    end

    # NOTE: batch_id is deliberately *not* a foreign key. The association is
    # polymorphic over Batch and MarcBatch, and the Rails app dropped the
    # constraint in 20210817212641_remove_foreign_key_constraint_from_absolute_identifiers.
    create_table :absolute_identifiers do
      primary_key :id, type: :Bignum, serial: true, identity: false
      column :barcode, "character varying"
      column :batch_id, :Bignum
      column :batch_type, "character varying", default: "Batch"
      column :created_at, "timestamp(6) without time zone", null: false
      column :holding_cache, :jsonb
      column :holding_id, "character varying"
      column :original_box_number, Integer
      column :pool_identifier, "character varying"
      column :prefix, "character varying"
      column :suffix, Integer
      column :sync_status, "character varying" # no DB default; set in the repo, as Rails set it via the Attributes API
      column :top_container_uri, "character varying"
      column :updated_at, "timestamp(6) without time zone", null: false

      index [:batch_id], name: :index_absolute_identifiers_on_batch_id
      index %i[prefix suffix pool_identifier], name: :absolute_identifiers_uniqueness, unique: true
    end
  end
end
