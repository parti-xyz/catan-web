class AddBodyFulltextIndexToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :body_ngram, :text, limit: 160.megabytes - 1
    add_index :posts, :body_ngram, type: :fulltext
  end
end
