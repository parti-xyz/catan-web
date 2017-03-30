class Survey < ActiveRecord::Base
  has_one :post, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  scope :limited, -> { where.not(duration: 0) }
  scope :need_to_reset_sent_closed_message_at, -> {
    limited.where('sent_closed_message_at < DATE(DATE_ADD(created_at, INTERVAL duration DAY))')
  }
  scope :need_to_send_closed_message, -> {
    limited.where('? > DATE(DATE_ADD(created_at, INTERVAL duration DAY))', DateTime.now).where(sent_closed_message_at: nil)
  }

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def open?
    return true if duration.days <= 0
    expire_at.future?
  end

  def visible_feedbacks?(someone)
    feedbacked?(someone) or !open?
  end

  def expire_at
    self.created_at + duration.days
  end

  def percentage(option)
    return 0 if feedbacks_count == 0 or option.feedbacks_count == 0

    (option.feedbacks_count / feedbacks_count.to_f * 100).ceil
  end

  def issue_for_message
    post.issue
  end

  def group_for_message
    post.issue.group
  end
end
