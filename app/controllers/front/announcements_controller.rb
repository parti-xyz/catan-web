class Front::AnnouncementsController < Front::BaseController
  def notice
    render_403 and return unless user_signed_in?

    @announcement = Announcement.find(params[:id])
    render_404 and return if @announcement.blank? || !@announcement.requested_to_notice?(current_user)

    outcome = NoticePost.run(current_group: current_group, current_user: current_user, announcement: @announcement)

    if outcome.errors.empty?
      flash.now[:notice] = I18n.t('activerecord.successful.messages.checked')
    else
      Rails.logger.error(outcome.errors.inspect)
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    @announcement.reload
    render(partial: '/front/posts/show/announcement', locals: { announcement: @announcement })
  end

  def hold_back
    render_403 and return unless user_signed_in?

    @announcement = Announcement.find(params[:id])
    render_404 and return if @announcement.blank? || !@announcement.requested_to_notice?(current_user)

    @member = current_group.member_of(current_user)
    @audience = @announcement.audiences.find_or_create_by(member: @member)

    @audience.noticed_at = nil
    if @audience.save
      flash.now[:notice] = I18n.t('activerecord.successful.messages.canceled')
    else
      Rails.logger.error(@audience.errors.inspect)
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    @announcement.reload
    render(partial: '/front/posts/show/announcement', locals: { announcement: @announcement })
  end

  def stop
    @announcement = Announcement.find(params[:id])
    render_403 and return unless can?(:stop, @announcement)

    @announcement.stopped_at = DateTime.now
    if @announcement.save
      flash.now[:notice] = I18n.t('activerecord.successful.messages.completed')
    else
      Rails.logger.error(@announcement.errors.inspect)
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    render(partial: '/front/posts/show/announcement', locals: { announcement: @announcement })
  end

  def restart
    @announcement = Announcement.find(params[:id])
    render_403 and return unless can?(:stop, @announcement)

    @announcement.stopped_at = nil
    if @announcement.save
      flash.now[:notice] = I18n.t('activerecord.successful.messages.completed')
    else
      Rails.logger.error(@announcement.errors.inspect)
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    render(partial: '/front/posts/show/announcement', locals: { announcement: @announcement })
  end

  def audiences
    @announcement = Announcement.find(params[:id])
    render layout: nil
  end
end