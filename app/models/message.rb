class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :messagable, polymorphic: true
end
