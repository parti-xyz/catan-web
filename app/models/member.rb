class Member < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    { parti: Issue::Entity,
      group: Group::Entity
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.capitalize.to_s)
      expose :"#{key}_joinable", using: entity, if: lambda { |instance, options| instance.joinable_type == type } do |instance|
        instance.joinable
      end
    end
    expose :id, :joinable_type
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
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}

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
    joinable.makers.exists? user: self.user
  end
end
