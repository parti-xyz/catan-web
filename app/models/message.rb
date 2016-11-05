class Message < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :comment_messagable, using: Comment::Entity, if: lambda { |instance, options| instance.messagable_type == 'Comment' } do |instance|
      instance.messagable
    end
    expose :upvote_messagable, using: Upvote::Entity, if: lambda { |instance, options| instance.messagable_type == 'Upvote' } do |instance|
      instance.messagable
    end
    expose :id, :messagable_type
    expose :user, using: User::Entity
    expose :sender, using: User::Entity
    expose :created_at
    expose :post, using: Post::Entity
    expose :desc do |instance|
      comment = nil
      key = case instance.messagable_type
      when 'Comment'
        comment = instance.messagable
        if instance.messagable.mentioned?(instance.user)
          'comment.mentioned'
        else
          'comment.created'
        end
      when 'Upvote'
        if instance.messagable.upvotable.is_a? Comment
          comment = instance.messagable.upvotable
          'upvote.comment'
        else
          'upvote.post'
        end
      end

      I18n.t("api.entities.message.desc.#{key}",
        post_desc: instance.messagable.post.specific_desc_striped_tags.truncate(100),
        comment_desc: (comment.body.truncate(100) if comment.present?))
    end
  end

  belongs_to :user
  belongs_to :messagable, polymorphic: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }

  before_save :mark_unread

  def sender
    messagable.sender_of_message
  end

  def post
    messagable.post
  end

  private

  def mark_unread
    user.increment!(:unread_messages_count)
  end
end
