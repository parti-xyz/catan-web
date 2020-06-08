class CreateWikiAuthors < ActiveRecord::Migration[5.2]
  def change
    create_table :wiki_authors do |t|
      t.references :user, index: true
      t.references :wiki, index: true
      t.timestamp null: false
    end

    add_index :wiki_authors, [:user_id, :wiki_id], unique: true

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Wiki.find_each(batch_size: 200).each do |wiki|
            WikiHistory.where(wiki_id: wiki.id).select(:user_id).distinct.pluck(:user_id).each do |user_id|
              wiki.wiki_authors.create(user_id: user_id)
            end
          end
        end
      end
    end
  end
end
