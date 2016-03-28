namespace :migrate do
  desc "Migrate discussions to talks"
  task :discussions_to_talks => :environment do
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

  desc "Migrate questions to talks"
  task :questions_to_talks => :environment do
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

  desc "Migrate talkable articles to talks"
  task :talkable_articles_to_talks => :environment do
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

  desc "Migrate link sources"
  task :link_sources => :environment do
    ActiveRecord::Base.transaction do
      Article.where(link_source_id: nil).find_each do |article|
        puts "#{article.id}"
        source = LinkSource.find_or_create_by! url: article.link
        article.link_source = source
        article.save!

        comment = build_comment_from_article(article)
        comment.save! unless comment.blank?
        Article.merge_by_link!(article)
      end
    end

    puts "crawling..."
    LinkSource.where(crawling_status: 'not_yet').find_each do |source|
      puts "#{source.url}"
      CrawlingJob.perform_async(source.id)
    end
  end

  desc "Remove questions, answers, discussions and proposals"
  task :destroy_qnas_and_dnps => :environment do
    ActiveRecord::Base.transaction do
      Post.where(postable_type: [Question, Answer, Discussion, Proposal]).find_each do |post|
        post.really_destroy!
      end
    end
  end

  def build_comment(talk, source, post)
    body = ActionController::Base.helpers.strip_tags(source.body)
    return if body.blank?
    talk.acting_as.comments.build(body: body, user_id: post.user_id, created_at: source.created_at, updated_at: source.updated_at)
  end

  def build_comment_from_article(article)
    body = ActionController::Base.helpers.strip_tags(article.body)
    return if body.blank?
    article.acting_as.comments.build(body: body, user_id: article.acting_as.user_id, created_at: article.created_at, updated_at: article.updated_at)
  end

  def build_comment_from_answers(talk, question, post)
    from_answers = question.answers.map { |a| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(a.body), user_id: a.post.user_id, created_at: a.created_at, updated_at: a.updated_at) }
    from_answer_comments = question.answers.map(&:comments).flatten.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }
    from_comments = question.comments.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }

    from_answers + from_answers + from_comments
  end

  def build_comment_from_proposals(talk, discussion, post)
    from_proposals = discussion.proposals.map { |a| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(a.body), user_id: a.post.user_id, created_at: a.created_at, updated_at: a.updated_at) }
    from_proposal_comments = discussion.proposals.map(&:comments).flatten.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }
    from_comments = discussion.comments.map { |c| talk.acting_as.comments.build(body: ActionController::Base.helpers.strip_tags(c.body), user_id: c.user_id, created_at: c.created_at, updated_at: c.updated_at) }

    from_proposals + from_proposals + from_comments
  end
end
