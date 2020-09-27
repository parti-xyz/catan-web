class Option < ApplicationRecord
  belongs_to :user
  belongs_to :survey
  has_many :feedbacks, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy
  scope :of_group, -> (group) { where(survey_id: Survey.of_group(group)) }

  def selected? someone
    return false if someone.blank?
    feedbacks.exists? user: someone
  end

  def canceled?
    canceled_at.present?
  end

  def post_for_message
    survey.post
  end

  def issue_for_message
    survey.post.issue
  end

  def group_for_message
    survey.post.issue.group
  end

  def feedback_users
    User.where(id: self.feedbacks.select(:user_id).distinct)
  end

  def percentage
    survey.percentage(self)
  end

  def mvp?
    survey.mvp_option?(self)
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end
end
