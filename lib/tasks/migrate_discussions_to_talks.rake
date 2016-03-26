desc "Migrate discussions to talks"
task :migrate_discussions_to_talks => :environment do
  ActiveRecord::Base.transaction do
    Discussion.all.find_each do |discussion|
      puts "#{discussion.id}"
      post = Post.find_by(postable: discussion)
      if post.present?
        talk = Talk.new(issue: post.issue, title: discussion.title, user: post.user, created_at: discussion.created_at, updated_at: discussion.updated_at)
        talk.save!
        puts "#{talk.id}"
        comment = build_comment(talk, discussion, post)
        comment.save! unless comment.blank?
        comments = build_comment_from_proposals(talk, discussion, post)
        comments.each do |c|
          c.save!
        end
      end
    end
  end
end

def build_comment(talk, discussion, post)
  body = ActionController::Base.helpers.strip_tags(discussion.body)
  return if body.blank?
  talk.acting_as.comments.build(body: body, user_id: post.user_id, created_at: discussion.created_at, updated_at: discussion.updated_at)
end

def build_comment_from_proposals(talk, discussion, post)
  from_proposals = discussion.proposals.map { |a| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(a.body), user_id: a.post.user_id, created_at: a.created_at, updated_at: a.updated_at) }
  from_proposal_comments = discussion.proposals.map(&:comments).flatten.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }
  from_comments = discussion.comments.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }

  from_proposals + from_proposals + from_comments
end
