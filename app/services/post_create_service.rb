class PostCreateService
  def initialize(post:, current_user:)
    @post = post
    @current_user = current_user
  end

  def call
    return false if @post.issue.blank?
    return false unless @post.issue.postable?(@current_user)

    @post.user = @current_user
    if @post.wiki.present?
      @post.wiki.last_author = @current_user
      @post.wiki.format_body
    end
    if @post.event.present?
      @post.event.roll_calls.build(user: @current_user, status: :attend)
    end
    @post.strok_by(@current_user)
    @post.format_body

    @post.setup_link_source
    set_current_user_to_options(@post, @current_user)

    @post.pinned = (@post.pinned? and Ability.new(@current_user, @post.issue.group).can?(:pin, @post))
    if @post.pinned?
      @post.pinned_at = DateTime.now
      @post.pinned_by = @current_user
    end

    ActiveRecord::Base.transaction do
      if @post.save
        if @post.announcement.present? && @post.announcement.announcing_mode.direct?
          direct_announced_users = User.parse_nicknames(@post.announcement.direct_announced_user_nicknames)

          newbie_members = @post.issue.group.members.where(user: direct_announced_users)

          newbie_members.each do |member|
            @post.announcement.audiences.create(member: member)
          end
        end
      else
        logger.errors(@post.errors.inspect)
        return false
      end
    end

    @post.read!(@current_user)
    StrokedPostUserJob.perform_async(@post.id, @current_user.id)
    @post.issue.strok_by!(@current_user, @post)
    @post.issue.read!(@current_user)
    crawling_after_creating_post
    @post.perform_messages_with_mentions_async(:create)
    if @post.pinned?
      PinJob.perform_async(@post.id, @current_user.id)
    end

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
