class Talk < ActiveRecord::Base
  include Searchable

  acts_as_paranoid
  acts_as :post, as: :postable

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }

  def origin
    self
  end

  def searchable_content
    self.title
  end
end
