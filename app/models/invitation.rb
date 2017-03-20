class Invitation < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id do
    { parti: Issue::Entity,
      group: Group::Entity
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.capitalize.to_s)
      expose :"#{key}_joinable", using: entity, if: lambda { |instance, options| instance.joinable_type == type } do |instance|
        instance.joinable
      end
    end
    expose :user, using: User::Entity
    expose :recipient, using: User::Entity
  end

  belongs_to :user
  belongs_to :recipient, class_name: User
  belongs_to :joinable, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :recipient, uniqueness: { scope: [:joinable_id, :joinable_type] }, if: 'recipient.present?'
  validates :joinable, presence: true
  validates :user, presence: true

  def issue
    joinable if joinable_type == 'Issue'
  end

  def sender_of_message(message)
    user
  end

  def issue_for_message
    issue
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end

  def recipient_email
    read_attribute(:recipient_email) || recipient.try(:email)
  end
end
