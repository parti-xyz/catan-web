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

    if @hottest_posts.any?
      mail(template_name: 'summary', to: @user.email,
        subject: "#{I18n.l Date.yesterday} 빠띠의 유쾌한 민주주의 소식입니다!",
        delivery_method: delivery_method,
        delivery_method_options: delivery_method_options)
    end
  end
end
