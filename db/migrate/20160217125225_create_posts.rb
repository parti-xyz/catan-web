class CreatePosts < ActiveRecord::Migration[4.2]
  def up
    create_table :posts do |t|
      t.references :issue, null: false, index: true
      t.references :postable, null: false, index: true, polymorphic: true
      t.references :user, null: false, index: true
      t.timestamps null: false
    end

    remove_column :articles, :user_id
    remove_column :articles, :issue_id
    remove_column :opinions, :user_id
    remove_column :opinions, :issue_id
  end

  def down
    raise "unimplemented"
  end
end
