namespace :migrate do
  desc "발제수다를 논의의 본문으로 옮깁니다"
  task :presetation_comment_to_talk_body => :environment do
    ActiveRecord::Base.transaction do
      talks = Talk.where(body: nil).each do |t|
        pre_comment = t.comments.first
        next unless t.user == pre_comment.try(:user)
        t.update_columns body: pre_comment.body
        t.post.update_columns upvotes_count: pre_comment.upvotes_count
        pre_comment.upvotes.each do |upvote|
          upvote.update_columns upvotable_id: t.post.id, upvotable_type: 'Post'
        end
        pre_comment.reload
        pre_comment.destroy
      end
    end
  end
end
