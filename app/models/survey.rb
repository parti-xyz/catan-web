class Survey < ActiveRecord::Base
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def open?
    return true if duration.days <= 0
    expire_at.future?
  end

  def expire_at
    self.created_at + duration.days
  end

  def percentage(option)
    return 0 if feedbacks_count == 0 or option.feedbacks_count == 0

    (option.feedbacks_count / feedbacks_count.to_f * 100).ceil
  end
end
