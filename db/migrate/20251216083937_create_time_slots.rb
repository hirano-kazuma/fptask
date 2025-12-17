class CreateTimeSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :time_slots do |t|
      t.references :fp, null: false, foreign_key: { to_table: :users }
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false

      t.timestamps
    end

    # 同じFPが同じ開始時刻の枠を重複して作れないようにする
    add_index :time_slots, [:fp_id, :start_time], unique: true
  end
end
