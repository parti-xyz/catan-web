class StatisticsJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    Comment.past_week.group(:post).count.each do |post, count|
      post.update_columns(latest_comments_count: count)
    end
  end
end
