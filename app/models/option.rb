class Option < ActiveRecord::Base
  belongs_to :user
  belongs_to :survey
  has_many :feedbacks, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy

  def selected? someone
    feedbacks.exists? user: someone
  end

  def issue_for_message
    survey.post.issue
  end

  def group_for_message
    survey.post.issue.group
  end
end
