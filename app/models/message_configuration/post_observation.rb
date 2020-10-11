class MessageConfiguration::PostObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :user
  belongs_to :post

  validates :user, uniqueness: { scope: [ :post_id ] }

  def self.of(user, post)
    find_or_initialize_by(user_id: user&.id, post_id: post.id) if user.present? && post.present?
  end

  def parent
    MessageConfiguration::IssueObservation.of(user, post.issue)
  end
end
