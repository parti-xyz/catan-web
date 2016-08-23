class TagsController < ApplicationController
  def show
    @issues = Issue.only_group_or_all_if_blank(current_group).tagged_with(params[:name]).hottest
  end
end
