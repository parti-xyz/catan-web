class AddPostEmojisToIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :post_emojis, :text
  end
end
