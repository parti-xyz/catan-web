class Message < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    { comment: Comment::Entity,
      upvote: Upvote::Entity,
      invitation: Invitation::Entity,
      parti: Issue::Entity,
      member: Member::Entity
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.capitalize.to_s)
      expose :"#{key}_messagable", using: entity, if: lambda { |instance, options| instance.messagable_type == type } do |instance|
        instance.messagable
      end
    end

    expose :id, :messagable_type
    expose :user, using: User::Entity
    expose :sender, using: User::Entity
    expose :created_at
    expose :post, using: Post::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :desc do |instance|
      ApplicationController.renderer.render(
        partial: "messages/api/#{instance.messagable.class.model_name.singular}",
        locals: { message: instance }
      )
    end
  end

  belongs_to :user
  belongs_to :sender, class_name: User
  belongs_to :messagable, polymorphic: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }

  before_save :mark_unread

  def post
    messagable.try(:post)
  end

  def issue
    messagable.issue_for_message
  end

  def action_params_hash
    JSON.parse(action_params)
  end

  private

  def mark_unread
    user.increment!(:unread_messages_count)
  end
end
