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

ActiveRecord::Schema.define(version: 2021_06_03_185502) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absolute_identifiers", force: :cascade do |t|
    t.integer "original_box_number"
    t.string "top_container_uri"
    t.integer "batch_id"
    t.string "prefix"
    t.integer "suffix"
    t.string "sync_status"
    t.string "pool_identifier"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "barcode"
  end

  create_table "batches", force: :cascade do |t|
    t.integer "start_box"
    t.integer "end_box"
    t.string "first_barcode"
    t.string "call_number"
    t.string "location_uri"
    t.string "container_profile_uri"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "resource_uri"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "remember_created_at"
    t.string "provider", default: "cas", null: false
    t.string "uid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

end
