class Survey < ApplicationRecord
  include Expirable

  has_one :post, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :options, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  scope :need_to_reset_sent_closed_message_at, -> {
    finite.where('sent_closed_message_at < expires_at')
  }
  scope :need_to_send_closed_message, -> {
    finite.where('? > expires_at', DateTime.now).where(sent_closed_message_at: nil)
  }
  scope :of_group, -> (group) { where(id: Post.of_group(group).select(:survey_id)) }

  def feedbacked?(someone)
    feedbacks.exists? user: someone
  end

  def visible_feedbacks?(someone)
    (feedbacked?(someone) and !hidden_intermediate_result?) or !open?
  end

  def percentage(option)
    max_feedbacks_count = options.maximum(:feedbacks_count)
    return 0 if max_feedbacks_count == 0 or option.feedbacks_count == 0
    (option.feedbacks_count / max_feedbacks_count.to_f * 100).ceil
  end

  def post_for_message
    post
  end

  def issue_for_message
    post.issue
  end

  def group_for_message
    post.issue.group
  end

  def mvp_options
    @mvp_options if @mvp_options.present?

    mvp_feedbacks_count = options.order(feedbacks_count: :desc).first.try(:feedbacks_count)
    @mvp_options ||= options.where(feedbacks_count: mvp_feedbacks_count)
    @mvp_options = Option.none if @mvp_options.count == options.count
    @mvp_options
  end

  def mvp_option?(option)
    mvp_options.exists?(id: option)
  end

  def feedback_users_count
    feedback_users.count
  end

  def feedback_users
    User.where(id: self.feedbacks.select(:user_id).distinct)
  end

  def changable_multiple_select?
    return true unless persisted?
    return true unless multiple_select?
    feedbacks.group(:user_id).having('count(id) > 1').empty?
  end

  def self.messagable_group_method
    :of_group
  end
end
