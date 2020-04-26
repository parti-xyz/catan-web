class AddChildrenCountToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :comments_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        transaction do
          execute <<-SQL.squish
            UPDATE comments
            SET comments_count = (SELECT tmp.cnt
                                  FROM (SELECT parent_id, count(1) as cnt
                                        FROM comments as child_comments
                                        GROUP BY parent_id) as tmp
                                  WHERE tmp.parent_id = comments.id)
          SQL

          execute <<-SQL.squish
            UPDATE comments
            SET comments_count = 0
            WHERE comments_count is NULL
          SQL
        end
      end
    end

    change_column_null :comments, :comments_count, false
  end
end
