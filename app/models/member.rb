class Member < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id do
    expose :issue, using: Issue::Entity, as: :parti
    expose :group, using: Group::Entity
    expose :user, using: User::Entity
    expose :is_maker do |instance|
      instance.is_maker?
    end
  end

  belongs_to :user
  belongs_to :joinable, counter_cache: true, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :joinable, presence: true
  validates :user, uniqueness: {scope: :joinable}

  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(id: :desc) }

  def issue
    joinable if joinable_type == 'Issue'
  end

  def issue_for_message
    issue
  end

  def group_for_message
    joinable if joinable_type == 'Group'
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
