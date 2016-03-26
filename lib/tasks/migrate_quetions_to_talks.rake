desc "Migrate questions to talks"
task :migrate_questions_to_talks => :environment do
  ActiveRecord::Base.transaction do
    Question.all.find_each do |question|
      puts "#{question.id}"
      post = Post.find_by(postable: question)
      if post.present?
        talk = Talk.new(issue: post.issue, title: question.title, user: post.user, created_at: question.created_at, updated_at: question.updated_at)
        talk.save!
        puts "#{talk.id}"
        comment = build_comment(talk, question, post)
        comment.save! unless comment.blank?
        comments = build_comment_from_answers(talk, question, post)
        comments.each do |c|
          c.save!
        end
      end
    end
  end
end

def build_comment(talk, question, post)
  body = ActionController::Base.helpers.strip_tags(question.body)
  return if body.blank?
  talk.acting_as.comments.build(body: body, user_id: post.user_id, created_at: question.created_at, updated_at: question.updated_at)
end

def build_comment_from_answers(talk, question, post)
  from_answers = question.answers.map { |a| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(a.body), user_id: a.post.user_id, created_at: a.created_at, updated_at: a.updated_at) }
  from_answer_comments = question.answers.map(&:comments).flatten.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }
  from_comments = question.comments.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }

  from_answers + from_answers + from_comments
end
