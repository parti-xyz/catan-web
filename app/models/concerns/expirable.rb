module Expirable
  include ActionView::Helpers::DateHelper
  extend ActiveSupport::Concern

  included do
    attr_accessor :duration_days
    scope :finite, -> { where.not(expires_at: nil) }
  end


  def open?
    expires_at.nil? or expires_at.future?
  end

  def setup_expires_at
    if self.duration_days.present?
      case self.duration_days
      when '-1'
        self.touch(:expires_at)
      when '0'
        self.expires_at = nil
      else
       self.assign_expires_after(self.duration_days.to_i.days)
      end
    end
  end

  def assign_expires_after(duration_days)
    self.expires_at = Time.current + duration_days
  end

  def remain_time_human
    if self.open?
      return I18n.t('views.survey.remain_time.undefined') if self.expires_at.nil?

      I18n.t('views.survey.remain_time.open', duration: distance_of_time_in_words_to_now(self.expires_at))
    else
      I18n.t('views.survey.remain_time.closed')
    end
  end

end
