class Talk < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable
  validates :title, presence: true, length: { maximum: 50 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  def origin
    self
  end

  def has_presentation?
    comments.any? and comments.first.user == user
  end

  def sequential_comments_but_presentation
    self.has_presentation? ? self.comments.sequential.offset(1) : self.comments.sequential
  end
end
