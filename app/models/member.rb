class Member < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue, counter_cache: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :issue, presence: true
  validates :user, uniqueness: {scope: :issue}

  scope :latest, -> { after(1.day.ago) }
end
