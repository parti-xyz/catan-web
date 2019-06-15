class PartiMailer < ApplicationMailer
  def summary_by_mailtrap(user)
    delivery_method_options = { user_name: ENV['MAILTRAP_USER_NAME'],
                         password: ENV['MAILTRAP_PASSWORD'],
                         address: 'mailtrap.io',
                         domain: 'mailtrap.io',
                         port: '2525',
                         authentication: :cram_md5 } unless Rails.env.test?
    summary(user, :smtp, delivery_method_options)
  end

  def summary(user, delivery_method = nil, delivery_method_options = nil)
    @user = user
    return unless @user.enable_mailing_summary?

    @hottest_posts = @user.watched_posts.hottest.past_week.limit(50)
    @hottest_posts = @hottest_posts.reject { |post| post.blinded?(@user) }[0...10]
    subject = ['이번 주엔 어떤 소식이 올라왔을까요?','이 주엔 어떤 일들이 있었는지 확인하세요.','어떤 이야기들이 나오고 있을까요?','잘지내시나요? 빠띠의 이야기들을 전합니다.','빠띠의 새 소식들을 확인해보세요.','이번 주 이야기들이 도착했습니다!'].sample

    if @hottest_posts.any?
      mail(template_name: 'summary', to: @user.email,
        subject: "#{I18n.l Date.yesterday} #{subject}",
        delivery_method: delivery_method,
        delivery_method_options: delivery_method_options)
    end
  end

  def on_create(organizer_id, user_id, issue_id)
    @organizer = User.find_by(id: organizer_id)
    @user = User.find_by(id: user_id)
    return unless @user.enable_mailing_summary?
    return if @organizer == @user

    @issue = Issue.with_deleted.find_by(id: issue_id)
    return if @user.blank? or @issue.blank? or @organizer.blank?

    mail(to: @user.email,
         subject: "[빠띠] #{@organizer.nickname}님이 #{@issue.title} 채널을 열었습니다.")
  end

  def on_destroy(organizer_id, user_id, issue_id, message)
    @organizer = User.find_by(id: organizer_id)
    @user = User.find_by(id: user_id)
    return unless @user.enable_mailing_summary?
    return if @organizer == @user

    @issue = Issue.with_deleted.find_by(id: issue_id)
    return if @user.blank? or @issue.blank?

    @message = message

    mail(to: @user.email,
         subject: "[빠띠] #{@organizer.nickname}님이 #{@issue.title} 채널을 닫습니다.")
  end
end
