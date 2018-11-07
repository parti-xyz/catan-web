class GroupHomeComponentPreference::IssuePostsFormat < ApplicationRecord
  belongs_to :group_home_component
  belongs_to :issue
end
