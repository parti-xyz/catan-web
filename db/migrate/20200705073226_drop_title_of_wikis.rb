class DropTitleOfWikis < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        transaction do
          execute <<-SQL
            UPDATE posts
               SET base_title = (
                 SELECT title
                   FROM wikis
                  WHERE wikis.id = posts.wiki_id
               )
          SQL
        end
      end
    end

    remove_columns :wikis, :title
  end
end
