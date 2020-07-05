class AddPostEmojisToIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :post_emojis, :text

    reversible do |dir|
      dir.up do
        transaction do
          Issue.find_each do |issue|
            issue.update_columns(post_emojis: issue.posts.pluck(:title).join&.scan(EmojiRegex::Regex)&.map{ |e| e }&.join)
          end
        end
      end
    end
  end
end
