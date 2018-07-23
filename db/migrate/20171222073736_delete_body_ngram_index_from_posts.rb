class DeleteBodyNgramIndexFromPosts < ActiveRecord::Migration[4.2]
  def change
    remove_index :posts, name: :index_posts_on_body_ngram
  end
end
