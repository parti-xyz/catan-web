class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  has_many :posts, dependent: :nullify
end
