class CreateAnnouncement < ActiveRecord::Migration[5.2]
  def change
    create_table :announcements do |t|
      t.integer :audiences_count, null: false, default: 0
      t.integer :noticed_audiences_count, null: false, default: 0
      t.string :announcing_mode, null: false, default: 'all'
      t.timestamps null: false
    end

    create_table :audiences do |t|
      t.references :announcement, index: true, null: false
      t.references :member, index: true, null: false
      t.datetime :noticed_at
      t.timestamps null: false
    end

    add_index :audiences, [:announcement_id, :member_id], unique: true

    add_reference :posts, :announcement, index: true, null: true
  end
end
