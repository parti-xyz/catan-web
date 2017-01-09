class Survey < ActiveRecord::Base
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  validate :has_options

  def has_options
    errors.add(:base, 'must add at least one options') if self.options.blank?
  end

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def open?
    return true if duration.days <= 0
    (self.created_at + duration.days).future?
  end

  def percentage(option)
    return 0 if feedbacks_count == 0 or option.feedbacks_count == 0

    (option.feedbacks_count / feedbacks_count.to_f * 100).ceil
  end
end
