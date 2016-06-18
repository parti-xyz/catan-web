class Note < ActiveRecord::Base
  acts_as :post, as: :postable

  validates :body, presence: true

  scope :recent, -> { includes(:post).order('posts.id desc') }

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end
end
