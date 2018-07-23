class AddFileSourcesCountToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :file_sources_count, :integer, default: 0
  end
end
