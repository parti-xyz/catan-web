class Watch < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue, counter_cache: true

  validates :user, presence: true
  validates :issue, presence: true
  validates :user, uniqueness: {scope: :issue}

  scope :latest, -> { after(1.day.ago) }

  def unwatchable?
    !issue.member?(user)
  end
end
