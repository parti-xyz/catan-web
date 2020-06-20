class AddLastWikiHistoryToWikis < ActiveRecord::Migration[5.2]
  def change
    add_column :wikis, :last_wiki_history_id, :integer, index: true

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Wiki.find_each(batch_size: 200).each do |wiki|
            last_wiki_history_id = WikiHistory.where(wiki_id: wiki.id).order(created_at: :desc).first&.id
            wiki.update_column('last_wiki_history_id', last_wiki_history_id)
          end
        end
      end
    end
  end
end
