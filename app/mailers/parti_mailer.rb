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
    return unless @user.enable_mailing?

    @hottest_posts = @user.watched_posts.hottest.limit(10)
    subject = ['이번 주엔 어떤 소식이 올라왔을까요?','이 주엔 어떤 일들이 있었는지 확인하세요.','어떤 이야기들이 나오고 있을까요?','잘지내시나요? 빠띠의 이야기들을 전합니다.','빠띠의 새 소식들을 확인해보세요.','이번 주 이야기들이 도착했습니다!'].sample

    if @hottest_posts.any?
      mail(template_name: 'summary', to: @user.email,
        subject: "#{I18n.l Date.yesterday} #{subject}",
        delivery_method: delivery_method,
        delivery_method_options: delivery_method_options)
    end
  end
end
