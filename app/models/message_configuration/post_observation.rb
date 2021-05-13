class MessageConfiguration::PostObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :user
  belongs_to :post

  validates :user, uniqueness: { scope: [ :post_id ] }

  def self.of(user, post)
    return if user.blank? || post.blank?

    find_or_initialize_by(user_id: user.id, post_id: post.id)
  end

  def parent
    MessageConfiguration::IssueObservation.of(user, post.issue)
  end

  def self.parent_class
    MessageConfiguration::IssueObservation
  end
end
