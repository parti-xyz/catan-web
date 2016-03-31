class Upvote < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment, counter_cache: true

  validates :user, presence: true
  validates :comment, presence: true
  validates :user, uniqueness: {scope: [:comment]}

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  after_create :send_message

  private

  def send_message
    MessageService.new(self).call
  end
end
