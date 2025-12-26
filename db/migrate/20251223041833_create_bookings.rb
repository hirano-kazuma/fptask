class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :time_slot, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.text :description, null: false

      t.timestamps
    end
  end
end
