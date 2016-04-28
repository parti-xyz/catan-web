class Comment < ActiveRecord::Base
  acts_as_paranoid

  include Choosable
  include Mentionable
  mentionable :body

  belongs_to :user
  belongs_to :post, counter_cache: true
  has_one :issue, through: :post
  has_many :upvotes, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :mentions, as: :mentionable, dependent: :destroy

  validates :user, presence: true
  validates :post, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :previous_of, ->(id) { where('comments.created_at < ?', with_deleted.find(id).created_at) if id.present? }
  scope :next_of, ->(id) { where('comments.created_at > ?', with_deleted.find(id).created_at) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :persisted, -> { where "id IS NOT NULL" }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}

  after_create :send_messages

  def linkable?
    post.try(:linkable?)
  end

  def upvoted_by? someone
    upvotes.exists? user: someone
  end

  def mentioned? someone
    mentions.exists? user: someone
  end

  def mentionable? someone
    return false if someone.blank?
    return false if someone == self.user
    return true if self.choice.blank?
    self.choice == self.post.voted_by(someone).try(:choice)
  end

  def sender_of_message
    user
  end

  private

  def send_messages
    MessageService.new(self).call
  end
end
