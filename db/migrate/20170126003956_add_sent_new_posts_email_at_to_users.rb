class AddSentNewPostsEmailAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :sent_new_posts_email_at, :date
  end
end
