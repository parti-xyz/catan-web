class Talk < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  scope :recent, -> { order(created_at: :desc) }

  def origin
    self
  end
end
