class Upvote < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment, counter_cache: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :comment, presence: true
  validates :user, uniqueness: {scope: [:comment]}

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  after_create :send_message

  def sender_of_message
    user
  end

  private

  def send_message
    MessageService.new(self).call
  end
end
