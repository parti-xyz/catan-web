namespace :user do
  def reset_counter(ids, modelClass, column)
    ids.each do |id|
      next unless modelClass.exists?(id: id)
      modelClass.reset_counters(id, column)
    end
  end

  desc "회원을 탈퇴처리합니다"
  task :delete, [:nickname] => :environment do |task, args|
    ActiveRecord::Base.transaction do
      user = User.find_by(nickname: args.nickname)
      if user.blank?
        puts '해당되는 회원이 없습니다.'
        next
      end
      post_ids_for_comments = user.comments.select(:post_id).distinct.pluck(:post_id)
      issue_ids_for_members = user.members.select(:issue_id).distinct.pluck(:issue_id)
      issue_ids_for_posts = user.posts.select(:issue_id).distinct.pluck(:issue_id)
      post_ids_for_upvotes = user.upvotes.where(upvotable_type: "Post").select(:upvotable_id).distinct.pluck(:upvotable_id)
      comments_ids_for_upvotes = user.upvotes.where(upvotable_type: "Comment").select(:upvotable_id).distinct.pluck(:upvotable_id)
      poll_ids_for_votings = user.votings.select(:poll_id).distinct.pluck(:poll_id)

      user.destroy!

      reset_counter post_ids_for_comments, Post, :comments
      reset_counter issue_ids_for_members, Issue, :members
      reset_counter issue_ids_for_posts, Issue, :posts
      reset_counter post_ids_for_upvotes, Post, :upvotes
      reset_counter comments_ids_for_upvotes, Comment, :upvotes
      reset_counter poll_ids_for_votings, Poll, :votings
    end
  end

  desc "회원의 이메일을 변경합니다."
  task :change_eamil, [:nickname, :new_email] => :environment do |task, args|
    ActiveRecord::Base.transaction do
      user = User.find_by(nickname: args.nickname)
      if user.blank?
        puts '해당되는 회원이 없습니다.'
        next
      end

      searched_users = User.where(email: args.new_email).where.not(id: user.id)
      if searched_users.any?
        puts '같은 이메일을 쓰는 유저가 이미 있습니다.'
        pp searched_users.to_a.inspect
        next
      end

      unless user.update_columns(email: args.new_email)
        puts '이메일 변경에 실패했습니다.'
      end

      puts user.reload.inspect
    end
  end
end
