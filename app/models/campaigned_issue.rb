class CampaignedIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :campaign
end
