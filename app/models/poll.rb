class Poll < ActiveRecord::Base
  belongs_to :talk

  validates :title, presence: true
end
