class ChangeMultipleFileSourcesPerPosts < ActiveRecord::Migration
  def change
    add_reference :file_sources, :post, index: true

    query = <<-SQL.squish
      UPDATE file_sources SET post_id = ( SELECT id FROM posts WHERE posts.reference_id = file_sources.id AND posts.reference_type = 'FileSource' )
    SQL
    ActiveRecord::Base.connection.execute query

    remove_index :posts, ["id", "reference_id", "reference_type"]
    remove_column :posts, :reference_type
    rename_column :posts, :reference_id, :link_source_id

    change_column_null :file_sources, :post_id, :false
  end
end
