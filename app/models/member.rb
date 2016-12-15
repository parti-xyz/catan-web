class Member < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id do
    expose :issue, using: Issue::Entity, as: :parti
    expose :user, using: User::Entity
    expose :is_maker do |instance|
      instance.is_maker?
    end
  end

  belongs_to :user
  belongs_to :issue, counter_cache: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :issue, presence: true
  validates :user, uniqueness: {scope: :issue}

  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(id: :desc) }

  def issue_for_message
    issue
  end

  def is_maker?
    is_maker = false
    issue.makers.each do |maker|
      if maker.user == user
        is_maker = true
      end
    end
    is_maker
  end
end
