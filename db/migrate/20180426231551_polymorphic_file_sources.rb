class PolymorphicFileSources < ActiveRecord::Migration
  def change
    add_reference :file_sources, :file_sourceable, polymorphic: true, index: { name: 'file_sourceable_index' }

    reversible do |dir|
      dir.up do
        query = "UPDATE file_sources SET file_sourceable_id = post_id, file_sourceable_type = 'Post'"
        ActiveRecord::Base.connection.execute query
        say query
        query = "DELETE FROM file_sources where post_id is null"
        ActiveRecord::Base.connection.execute query
        say query
      end

      change_column_null :file_sources, :file_sourceable_id, false
      change_column_null :file_sources, :file_sourceable_type, false
    end
  end
end
