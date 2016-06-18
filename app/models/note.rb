class Note < ActiveRecord::Base
  acts_as :post, as: :postable

  validates :body, presence: true

  scope :recent, -> { includes(:post).order('posts.id desc') }
  scope :latest, -> { after(1.day.ago) }

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end
end
