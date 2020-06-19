class SurveyMailer < ApplicationMailer
  def self.deliver_all_later_on_closed(survey)
    return if survey.blank?

    survey.post.messagable_users.each do |user|
      on_closed(user.id, survey.id).deliver_later
    end
  end

  def on_closed(user_id, survey_id)
    @survey = Survey.find_by(id: survey_id)
    @user = User.find_by(id: user_id)
    return if @survey.blank? or @user.blank? or !@user.enable_mailing_poll_or_survey?

    return if @survey&.post&.issue&.group&.cloud_plan?

    mail(to: @user.email,
         subject: "[#{I18n.t('labels.app_name_human')}] #{@survey.post.user.nickname}님이 올린 설문의 결과가 나왔습니다 : #{@survey.post.specific_desc_striped_tags(50)}")
  end
end
