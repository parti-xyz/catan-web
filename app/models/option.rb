class Option < ActiveRecord::Base
  belongs_to :survey
  has_many :feedbacks, dependent: :destroy

  def selected? someone
    feedbacks.exists? user: someone
  end
end
