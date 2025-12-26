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

ActiveRecord::Schema[8.1].define(version: 2025_12_16_101844) do
  create_table "time_slots", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.bigint "fp_id", null: false
    t.datetime "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["fp_id", "start_time"], name: "index_time_slots_on_fp_id_and_start_time", unique: true
    t.index ["fp_id"], name: "index_time_slots_on_fp_id"
    t.check_constraint "`end_time` > `start_time`", name: "check_end_time_after_start_time"
    t.check_constraint "minute(`end_time`) in (0,30)", name: "check_end_time_minutes"
    t.check_constraint "minute(`start_time`) in (0,30)", name: "check_start_time_minutes"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "time_slots", "users", column: "fp_id"
end
