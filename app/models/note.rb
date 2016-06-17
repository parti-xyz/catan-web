class Note < ActiveRecord::Base
  acts_as :post, as: :postable
end
