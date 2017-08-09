class AddBodyFulltextIndexToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :body_ngram, :text, limit: 65535 * 5
    add_index :posts, :body_ngram, type: :fulltext
  end
end
