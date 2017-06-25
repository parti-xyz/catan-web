class MemberRequest < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id, :reject_message do
    expose :user, using: User::Entity
    { group: Group::Entity,
      parti: Issue::Entity,
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.to_s.classify)
      expose :"#{key}_joinable", using: entity, if: lambda { |instance, options| instance.joinable_type == type } do |instance|
        instance.joinable
      end
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :joinable, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :joinable, presence: true
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}
  scope :recent, -> { order(id: :desc) }

  def issue_for_message
    joinable if joinable_type == 'Issue'
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end
end
