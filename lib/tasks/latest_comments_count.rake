namespace :latest_comments_count do
  desc "reset latest_comments_counted_datestamp"
  task :reset_datestamp => :environment do
    ActiveRecord::Base.transaction do
      Post.where("latest_comments_count > 0").find_each do |post|
        counted_at_date = (post.comments.newest.created_at + 7.days).to_date
        counted_at_date = Date.today if counted_at_date.future?

        post.update_columns(latest_comments_counted_datestamp: counted_at_date.strftime('%Y%m%d'))
      end
    end
  end
end
