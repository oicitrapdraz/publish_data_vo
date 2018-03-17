# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180213041325) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "data_products", force: :cascade do |t|
    t.integer "status"
    t.string "schema"
    t.string "resource_directory"
    t.string "filename"
    t.string "format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fits_columns", force: :cascade do |t|
    t.bigint "data_product_id"
    t.integer "hdu_index"
    t.string "identifier"
    t.string "name"
    t.string "description"
    t.string "type_alt"
    t.integer "verb_level"
    t.string "unit"
    t.string "ucds"
    t.boolean "required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_product_id"], name: "index_fits_columns_on_data_product_id"
  end

  create_table "metadata", force: :cascade do |t|
    t.bigint "data_product_id"
    t.string "title"
    t.text "description"
    t.string "creators"
    t.string "subjects"
    t.string "instrument"
    t.string "facility"
    t.string "type_alt"
    t.string "coverage_profile"
    t.string "coverage_waveband"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_product_id"], name: "index_metadata_on_data_product_id"
  end

  add_foreign_key "fits_columns", "data_products"
  add_foreign_key "metadata", "data_products"
end
