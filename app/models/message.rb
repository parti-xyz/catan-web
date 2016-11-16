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
    # expose :post, using: Post::Entity
    expose :desc do |instance|
      key = case instance.messagable_type
      when 'Comment'
        if instance.messagable.post.user == instance.user
          'comment.created_at_my_post'
        elsif instance.messagable.mentioned?(instance.user)
          'comment.mentioned'
        else
          'comment.created_at_other_post'
        end
      when 'Upvote'
        if instance.messagable.upvotable.is_a? Comment
          'upvote.comment'
        else
          'upvote.post'
        end
      when 'Member'
        'member.join'
      when 'Invitation'
        'invitation'
      when 'Issue'
        'issue'
      end

      I18n.t("api.entities.message.desc.#{key}",
        sender: instance.sender.nickname,
        writer_of_post: (instance.messagable.post.user.nickname if instance.messagable_type == 'Comment'),
        issue_title: (instance.messagable.issue_for_message.title if (instance.messagable_type == 'Member' || instance.messagable_type == 'Invitation' || instance.messagable_type == 'Issue')),
        previous_issue_title: (instance.action_params_hash["previous_title"] if instance.messagable_type == 'Issue'))
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
    messagable.post
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
