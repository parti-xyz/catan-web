class CreateVotings < ActiveRecord::Migration[4.2]
  def change
    create_table :votings do |t|
      t.references :user, null: false, index: true
      t.references :poll, null: false, index: true
      t.string :choice, null: false
      t.timestamps null: false
    end

    add_index :votings, [:poll_id, :user_id], unique: true
  end
end
