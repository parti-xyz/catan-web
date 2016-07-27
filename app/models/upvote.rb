class Upvote < ActiveRecord::Base
  belongs_to :user
  belongs_to :upvotable, polymorphic: true, counter_cache: true
  has_one :post, through: :comment, source: :post
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :upvotable, presence: true
  validates :user, uniqueness: {scope: [:upvotable]}

  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of, ->(id) { where('id < ?', id) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}

  after_create :send_message

  def sender_of_message
    user
  end

  private

  def send_message
    MessageService.new(self).call
  end
end
