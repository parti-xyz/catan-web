class Section < ActiveRecord::Base
  DEFAULT_NAME = '기본'

  belongs_to :issue
  has_many :talks

  validates :issue, presence: true
  validates :name, presence: true
end
