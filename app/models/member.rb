class Member < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id do
    expose :issue, using: Issue::Entity, as: :parti
    expose :user, using: User::Entity
  end

  belongs_to :user
  belongs_to :issue, counter_cache: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :issue, presence: true
  validates :user, uniqueness: {scope: :issue}

  scope :latest, -> { after(1.day.ago) }

  def issue_for_message
    issue
  end
end
