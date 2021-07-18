class MessageConfiguration::GroupObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :user
  belongs_to :group

  validates :user, uniqueness: { scope: [ :group_id ] }

  def self.of(user, group)
    return if user.blank? || group.blank?

    find_or_initialize_by(user_id: user.id, group_id: group.id)
  end

  def parent
    MessageConfiguration::RootObservation.of(group)
  end

  def self.parent_class
    MessageConfiguration::RootObservation
  end
end
