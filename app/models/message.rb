class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :messagable, polymorphic: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }

  def sender
    messagable.sender_of_message
  end

  def post
    messagable.post
  end
end
