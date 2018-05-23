class Member < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    { parti: Issue::Entity,
      group: Group::Entity
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.to_s.classify)
      expose :"#{key}_joinable", using: entity, if: lambda { |instance, options| instance.joinable_type == type } do |instance|
        instance.joinable
      end
    end
    expose :id, :joinable_type
    expose :user, using: User::Entity
    expose :is_organizer do |instance|
      instance.is_organizer?
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :joinable, counter_cache: true, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :readers, dependent: :destroy
  belongs_to :admit_user

  validates :user, presence: true
  validates :joinable, presence: true, on: :update
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}

  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(created_at: :desc).order(id: :desc) }
  scope :previous_of_recent, ->(member) {
    base = recent
    base = base.where('members.created_at <= ?', member.created_at) if member.present?
    base = base.where('id < ?', member.id) if member.present?
    base
  }
  scope :of_group, -> (group) {
    where.any_of(
      Member.where(joinable_type: 'Issue', joinable_id: Issue.of_group(group)),
      Member.where(joinable_type: 'Group', joinable_id: group.id)
    )
  }

  scoped_search relation: :user, on: [:nickname]
  scoped_search relation: :user, on: [:nickname, :email], profile: :admin

  def issue
    joinable if joinable_type == 'Issue'
  end

  def issue_for_message
    issue
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end

  def self.messagable_group_method
    :of_group
  end
end
