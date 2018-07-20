class ActiveIssueStat < ApplicationRecord
  belongs_to :issue, optional: true
end
