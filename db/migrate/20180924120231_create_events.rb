class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :all_day_long, default: false
      t.string :location
      t.text :body
      t.boolean :enable_self_attendance, default: true
      t.timestamps null: false
    end

    add_reference :posts, :event, index: true

    create_table :roll_calls do |t|
      t.references :user, null: false, index: true
      t.references :event, null: false, index: true
      t.string :status, null: false
      t.timestamps null: false
    end

    add_index :roll_calls, [:user_id, :event_id], unique: true
  end
end
