class Opinion < ActiveRecord::Base
  include Postable
  acts_as_paranoid
  acts_as :post, as: :postable
  validates :title, presence: true, length: { maximum: 50 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_recent, ->(opinion) {
    base = recent
    base = base.where('opinions.created_at < ?', opinion.created_at) if opinion.present?
    base
  }

  def specific_origin
    self
  end
end
