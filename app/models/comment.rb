class Comment < ActiveRecord::Base
  acts_as_paranoid

  include Choosable
  include Mentionable
  mentionable :body

  belongs_to :user
  belongs_to :post, counter_cache: true
  has_one :issue, through: :post

  validates :user, presence: true
  validates :post, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :persisted, -> { where "id IS NOT NULL" }

  def linkable?
    post.try(:linkable?)
  end
end
