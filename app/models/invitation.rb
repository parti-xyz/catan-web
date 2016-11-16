class Invitation < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id do
    expose :issue, using: Issue::Entity, as: :parti
    expose :user, using: User::Entity
    expose :recipient, using: User::Entity
  end

  belongs_to :user
  belongs_to :recipient, class_name: User
  belongs_to :issue
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, uniqueness: { scope: :recipient_id }, presence: true
  validates :recipient, presence: true
  validates :issue, presence: true

  def sender_of_message(message)
    user
  end

  def issue_for_message
    issue
  end
end
