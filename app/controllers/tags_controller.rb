class TagsController < ApplicationController
  def show
    @issues = Issue.in_group(current_group).tagged_with(params[:name]).hottest
  end
end
