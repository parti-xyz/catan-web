class CreateCommentReaders < ActiveRecord::Migration[4.2]
  def change
    create_table :comment_readers do |t|
      t.references :comment, index: true, null: false
      t.references :user, index: true, null: false
      t.timestamps null: false
    end
  end
end
