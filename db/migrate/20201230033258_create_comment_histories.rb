class CreateCommentHistories < ActiveRecord::Migration[5.2]
  def up
    create_table :comment_histories do |t|
      t.references :comment, null: false, index: true
      t.references :user, null: false, index: true
      t.text :body, limit: 16777215
      t.string :code, null: false
      t.integer :diff_body_adds_count, default: 0
      t.integer :diff_body_removes_count, default: 0
      t.boolean :trivial_update_body, default: false, null: false
      t.timestamps null: false
    end

    transaction do
      execute "INSERT INTO comment_histories(comment_id, user_id, body, code, created_at, updated_at) SELECT comments.id, comments.user_id, comments.body, 'create', comments.created_at, comments.updated_at FROM comments"
    end

    add_column :comments, :last_comment_history_id, :integer, index: true

    transaction do
      execute 'UPDATE comments SET last_comment_history_id = (SELECT min(comment_histories.id) FROM comment_histories WHERE comment_histories.comment_id = comments.id)'
    end

    add_column :comments, :comment_histories_count, :integer, default: 0
    add_column :comments, :last_author_id, :integer, index: true

    transaction do
      execute 'UPDATE comments SET last_author_id = user_id'
    end

    change_column_null :comments, :last_author_id, false

    create_table :comment_authors do |t|
      t.references :user, index: true
      t.references :comment, index: true
      t.timestamps null: false
    end

    add_index :comment_authors, [:user_id, :comment_id], unique: true

    transaction do
      execute 'INSERT INTO comment_authors(user_id, comment_id, created_at, updated_at) SELECT comments.user_id, comments.id, comments.created_at, comments.updated_at FROM comments'
    end
  end

  def down
    drop_table :comment_histories
    remove_column :comments, :comment_histories_count
    remove_column :comments, :last_author_id
    remove_column :comments, :last_comment_history_id
    drop_table :comment_authors
  end
end
