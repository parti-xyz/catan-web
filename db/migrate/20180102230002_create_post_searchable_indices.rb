class CreatePostSearchableIndices < ActiveRecord::Migration
  def change
    create_table :post_searchable_indices, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC" do |t|
      t.references :post, null: false, index: true
      t.text :ngram, limit: 65535 * 5
      t.timestamps
    end

    add_index :post_searchable_indices, :ngram, type: :fulltext

    reversible do |dir|
      dir.up do
        query = 'ALTER TABLE post_searchable_indices CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'
        ActiveRecord::Base.connection.execute query
        say query

        query = 'INSERT INTO post_searchable_indices(post_id, ngram) SELECT id, body_ngram FROM posts'
        ActiveRecord::Base.connection.execute query
        say query
      end
    end
  end
end
