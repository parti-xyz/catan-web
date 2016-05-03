class AddLatestCommentsCountedDatestampToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :latest_comments_counted_datestamp, :string
  end
end
