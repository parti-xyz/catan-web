class SummaryJob
  include Sidekiq::Worker

  def perform
    User.need_to_delivery(SummaryEmail::SITE_WEEKLY).before(7.days.ago, field: :last_sign_in_at).limit(300).each do |user|
      summary(user)
    end
  end

  def summary(user)
    if user.need_to_delivery?(SummaryEmail::SITE_WEEKLY)
      user.mail_delivered!(SummaryEmail::SITE_WEEKLY)
      PartiMailer.summary(user).deliver_now
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
  end
end
