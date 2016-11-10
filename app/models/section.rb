class Section < ActiveRecord::Base
  DEFAULT_NAME = '일반'

  belongs_to :issue
  has_many :posts do
    def move_to(other)
      update_all(section_id: other)
    end
  end

  validates :name, presence: true

  scope :resent, -> { self.order(created_at: :asc) }
end
