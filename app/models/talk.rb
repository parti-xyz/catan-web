class Talk < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  def origin
    self
  end
end
