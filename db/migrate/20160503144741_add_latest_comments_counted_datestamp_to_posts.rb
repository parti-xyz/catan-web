class AddLatestCommentsCountedDatestampToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :latest_comments_counted_datestamp, :string
  end
end
