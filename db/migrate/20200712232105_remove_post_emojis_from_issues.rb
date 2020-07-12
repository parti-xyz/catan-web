class RemovePostEmojisFromIssues < ActiveRecord::Migration[5.2]
  def change
    remove_column :issues, :post_emojis
  end
end
