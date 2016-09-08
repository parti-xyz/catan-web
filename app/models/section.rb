class Section < ActiveRecord::Base
  DEFAULT_NAME = '기본'

  belongs_to :issue

  validates :issue, presence: true
  validates :name, presence: true
end
