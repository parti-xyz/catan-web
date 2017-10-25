class PostCreateService
  def initialize(post:, current_user:)
    @post = post
    @current_user = current_user
  end

  def call
    return false if @post.issue.blank?
    return false unless @post.issue.safe_postable?(@current_user)

    @post.user = @current_user
    @post.wiki.last_author = @current_user if @post.wiki.present?
    @post.strok_by(@current_user)
    @post.format_body

    @post.setup_link_source
    set_current_user_to_options(@post, @current_user)
    return false unless @post.save

    @post.issue.strok_by!(@current_user, @post)
    crawling_after_creating_post
    @post.perform_mentions_async

    return true
  end

  private

  def set_current_user_to_options(post, current_user)
    (post.survey.try(:options) || []).each do |option|
      option.user = current_user
    end
  end

  def crawling_after_creating_post
    if @post.link_source.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@post.link_source.id)
    end
  end
end
