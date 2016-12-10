class Upvote < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :id, :upvotable_type, :upvotable_id
    expose :user, using: User::Entity
  end

  belongs_to :user
  belongs_to :upvotable, polymorphic: true, counter_cache: true
  belongs_to :issue
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :upvotable, presence: true
  validates :user, uniqueness: {scope: [:upvotable_id, :upvotable_type]}

  scope :recent, -> { order(created_at: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :previous_of, ->(id) { where('id < ?', id) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { where(issue: issue) }
  scope :comment_only, -> { where(upvotable_type: 'Comment') }

  after_create :send_message
  before_save :set_issue

  def sender_of_message(message)
    user
  end

  def post
    upvotable.is_a?(Post) ? upvotable : upvotable.post
  end

  def issue_for_message
    issue
  end

  private

  def send_message
    MessageService.new(self).call
  end

  def set_issue
    self.issue = upvotable.issue
  end
end
