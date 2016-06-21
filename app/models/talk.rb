class Talk < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable
  validates :title, presence: true, length: { maximum: 50 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  def specific_origin
    self
  end

  def has_presentation?
    comments.any? and comments.first.user == user
  end

  def is_presentation?(comment)
    return false unless has_presentation?
    comment == comments.first
  end

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end

  def best_comment
    comments.where('comments.upvotes_count >= ?', (Rails.env.development? ? 0 : 3)).order(upvotes_count: :desc).limit(1).first
  end

  def sequential_comments_but_presentation
    self.has_presentation? ? self.comments.sequential.offset(1) : self.comments.sequential
  end
end
