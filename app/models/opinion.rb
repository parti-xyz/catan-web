class Opinion < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable
  validates :title, presence: true, length: { maximum: 50 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_opinion, ->(opinion) { where('opinions.created_at < ?', opinion.created_at) if opinion.present? }

  def origin
    self
  end
end
