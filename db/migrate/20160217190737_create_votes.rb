class CreateVotes < ActiveRecord::Migration[4.2]
  def change
    create_table :votes do |t|
      t.references :user, null: false, index: true
      t.references :opinion, null: false, index: true
      t.string :choice, null: false
      t.timestamps null: false
    end

    add_index :votes, [:opinion_id, :user_id], unique: true
  end
end
