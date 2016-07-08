class Maker < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  #validates :user, uniqueness: {scope: [:issue]}
end
