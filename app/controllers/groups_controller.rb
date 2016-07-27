class GroupsController < ApplicationController
  def index
    @issues = Issue.in_group(current_group).sort{ |a, b| a.compare_title(b) }
  end
end
