class Admin::NoticeEmailController < AdminController
  def deliver
    logger.info("NoticeEmail by #{current_user.nickname}")
    SiteNoticeJob.perform_async(params[:title], params[:body], (current_user.id if params[:test_commit].present?))
  end
end
