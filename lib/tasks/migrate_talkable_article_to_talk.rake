desc "Migrate talkable article to talk"
task :migrate_talkable_article_to_talk => :environment do
  ActiveRecord::Base.transaction do
    Article.with_deleted.where.any_of({link: nil} , {link: ''}).find_each do |article|
      puts "#{article.id}"
      post = Post.with_deleted.find_by(postable: article)
      if post.present?
        talk = Talk.new(issue: post.issue, title: article.title, user: post.user, created_at: article.created_at, updated_at: article.updated_at)
        talk.save!
        comment = build_comment(talk, article, post)
        comment.save! unless comment.blank?
      end
      article.really_destroy!
    end
  end
end

def build_comment(talk, article, post)
  body = ActionController::Base.helpers.strip_tags(article.body)
  return if body.blank?
  talk.acting_as.comments.build(body: body, user_id: post.user_id, created_at: article.created_at, updated_at: article.updated_at)
end
