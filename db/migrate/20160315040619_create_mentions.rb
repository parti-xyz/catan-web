class CreateMentions < ActiveRecord::Migration[4.2]
  def change
    create_table :mentions do |t|
      t.references :user, null: false, index: true
      t.references :mentionable, null: false, index: true, polymorphic: true
      t.timestamps null: false
    end

    add_index :mentions, [:user_id, :mentionable_id, :mentionable_type], name: :uniq_user_mention, unique: true
  end
end
