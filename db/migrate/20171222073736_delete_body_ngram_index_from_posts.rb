class DeleteBodyNgramIndexFromPosts < ActiveRecord::Migration
  def change
    remove_index :posts, name: :index_posts_on_body_ngram
  end
end
