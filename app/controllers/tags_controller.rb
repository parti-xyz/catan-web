class TagsController < ApplicationController
  def show
    @issues = Issue.displayable_in_current_group(current_group).tagged_with(params[:name]).hottest
  end
end
