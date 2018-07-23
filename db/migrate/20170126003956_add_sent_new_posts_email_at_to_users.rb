class AddSentNewPostsEmailAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :sent_new_posts_email_at, :date
  end
end
