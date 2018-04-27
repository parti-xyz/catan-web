class AddFileSourcesCountToComments < ActiveRecord::Migration
  def change
    add_column :comments, :file_sources_count, :integer, default: 0
  end
end
