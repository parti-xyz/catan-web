class OpinionToTalk < ActiveRecord::Base
  belongs_to :opinion
  belongs_to :talk
end
