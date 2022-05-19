# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_05_19_150752) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absolute_identifiers", force: :cascade do |t|
    t.integer "original_box_number"
    t.string "top_container_uri"
    t.string "prefix"
    t.integer "suffix"
    t.string "sync_status"
    t.string "pool_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "barcode"
    t.bigint "batch_id"
    t.string "batch_type", default: "Batch"
    t.string "holding_id"
    t.jsonb "holding_cache"
    t.index ["batch_id"], name: "index_absolute_identifiers_on_batch_id"
    t.index ["prefix", "suffix", "pool_identifier"], name: "absolute_identifiers_uniqueness", unique: true
  end

  create_table "batches", force: :cascade do |t|
    t.integer "start_box"
    t.integer "end_box"
    t.string "first_barcode"
    t.string "call_number"
    t.string "location_uri"
    t.string "container_profile_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource_uri"
    t.bigint "user_id"
    t.jsonb "location_data"
    t.jsonb "container_profile_data"
    t.boolean "generate_abid", default: true
    t.index ["user_id"], name: "index_batches_on_user_id"
  end

  create_table "marc_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_marc_batches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "remember_created_at", precision: nil
    t.string "provider", default: "cas", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "aspace_uri"
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "batches", "users"
  add_foreign_key "marc_batches", "users"
end
