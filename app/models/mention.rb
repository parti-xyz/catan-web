class Mention < ActiveRecord::Base
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user, uniqueness: {scope: [:mentionable]}

  def sender_of_message
    mentionable.user
  end
end
