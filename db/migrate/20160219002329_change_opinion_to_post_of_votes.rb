class ChangeOpinionToPostOfVotes < ActiveRecord::Migration[4.2]
  class Vote < ApplicationRecord
  end

  def up
    add_reference :votes, :post

    Vote.all.each do |vote|
      result = ActiveRecord::Base.connection.execute "SELECT posts.id FROM votes, posts WHERE votes.opinion_id = posts.postable_id and 'opinion' = posts.postable_type"
      if result.empty?
        query = "DELETE FROM votes WHERE id = #{vote.id}"
      else
        post_id = result[:post_id]
        query = "UPDATE votes SET post_id = #{post_id}"
      end
      ActiveRecord::Base.connection.execute query
      say query
    end

    remove_index :votes, [:opinion_id, :user_id]
    remove_column :votes, :opinion_id
    change_column_null :votes, :post_id, false
    add_index :votes, [:post_id, :user_id], unique: true
  end

  def down
    raise "unimplemented"
  end
end
