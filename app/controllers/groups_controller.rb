class GroupsController < ApplicationController
  def index
    @issues = Issue.in_group(current_group).recent_touched
  end
end
