class AddFileSourcesCountToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :file_sources_count, :integer, default: 0
  end
end
