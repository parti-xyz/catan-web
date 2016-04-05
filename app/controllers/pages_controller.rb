class PagesController < ApplicationController
  def home
    redirect_to issue_home_path(Issue::OF_ALL)
  end

  def about
  end
end
