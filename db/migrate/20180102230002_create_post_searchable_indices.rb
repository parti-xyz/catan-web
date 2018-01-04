class CreatePostSearchableIndices < ActiveRecord::Migration
  def change
    create_table :post_searchable_indices do |t|
      t.references :post, null: false, index: true
      t.text :ngram, limit: 65535 * 5
      t.timestamps
    end

    add_index :post_searchable_indices, :ngram, type: :fulltext

    reversible do |dir|
      dir.up do
        query = 'INSERT INTO post_searchable_indices(post_id, ngram) SELECT id, body_ngram FROM posts'
        ActiveRecord::Base.connection.execute query
        say query
      end
    end
  end
end