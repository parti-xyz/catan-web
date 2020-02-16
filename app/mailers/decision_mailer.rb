class DecisionMailer < ApplicationMailer


  def on_update(decision_history_id, decision_user_id, user_id)
    @decision_history = DecisionHistory.find_by(id: decision_history_id)
    return if @decision_history.blank?

    @post = Post.find_by(id: @decision_history.post_id)
    @user = User.find_by(id: user_id)
    return if @post.blank? or @user.blank? or !@user.enable_mailing_poll_or_survey? or @user.email.blank?

    @decision_user = User.find_by(id: decision_user_id)
    mail(from: build_from(@decision_user), to: @user.email,
      subject: "[#{I18n.t('labels.app_name_human')}] \"#{@post.specific_desc_striped_tags(50)}\" 게시글 토론이 정리되었습니다.")
  end
end
