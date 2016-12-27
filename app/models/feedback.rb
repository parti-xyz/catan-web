class Feedback < ActiveRecord::Base
  belongs_to :user
  belongs_to :survey, counter_cache: true
  belongs_to :option, counter_cache: true
end
