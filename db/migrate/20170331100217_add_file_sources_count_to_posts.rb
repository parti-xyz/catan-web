class AddFileSourcesCountToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :file_sources_count, :integer, default: 0
  end
end
