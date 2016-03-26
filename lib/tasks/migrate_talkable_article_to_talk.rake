desc "Migrate talkable article to talk"
task :migrate_talkable_article_to_talk => :environment do
  ActiveRecord::Base.transaction do
    Article.with_deleted.where.any_of({link: nil} , {link: ''}).find_each do |article|
      if Post.with_deleted.exists?(postable: article)
        talk = Talk.new(issue: article.issue, title: article.title, user: article.user, created_at: article.created_at, updated_at: article.updated_at)
        comment = build_comment(talk, article)
        talk.save!
        comment.save! unless comment.blank?
      end
      article.really_destroy!
    end
  end
end

def build_comment(talk, article)
  body = ActionController::Base.helpers.strip_tags(article.body)
  return if body.blank?
  talk.acting_as.comments.build(body: body, user_id: article.user_id)
end
