class MigrateAskParti < ActiveRecord::Migration
  def up
    ask_parti = Issue.find_by slug: 'ask-parti'
    return if ask_parti.blank?
    parti_parti = Issue.find_by slug: 'parti'
    return if parti_parti.blank?

    ActiveRecord::Base.transaction do
      query = "UPDATE articles SET post_issue_id = #{parti_parti.id} WHERE post_issue_id = #{ask_parti.id}"
      ActiveRecord::Base.connection.execute query
      say query

      ask_parti.makers.where(user: parti_parti).each do |maker|
        query = "DELETE FROM makers WHERE id = #{maker.id}"
        ActiveRecord::Base.connection.execute query
        say query
      end

      query = "UPDATE makers SET issue_id = #{parti_parti.id} WHERE issue_id = #{ask_parti.id}"
      ActiveRecord::Base.connection.execute query
      say query

      query = "UPDATE posts SET issue_id = #{parti_parti.id} WHERE issue_id = #{ask_parti.id}"
      ActiveRecord::Base.connection.execute query
      say query

      query = "UPDATE relateds SET issue_id = #{parti_parti.id} WHERE issue_id = #{ask_parti.id}"
      ActiveRecord::Base.connection.execute query
      say query

      ask_parti.watches.select{ |watch| parti_parti.watched_by?(watch.user) }.each do |watch|
        query = "DELETE FROM watches WHERE id = #{watch.id}"
        ActiveRecord::Base.connection.execute query
        say query
      end

      query = "UPDATE watches SET watchable_id = #{parti_parti.id} WHERE watchable_id = #{ask_parti.id} AND watchable_type = 'Issue'"
      ActiveRecord::Base.connection.execute query
      say query

      ask_parti.destroy
    end
  end

  def down
    raise "unimplemented"
  end
end
