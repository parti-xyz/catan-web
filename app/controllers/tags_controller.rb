class TagsController < ApplicationController
  def show
    @issues = Issue.tagged_with(params[:name]).hottest
  end
end
