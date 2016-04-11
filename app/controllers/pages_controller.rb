class PagesController < ApplicationController
  def home
    redirect_to issue_home_path(Issue::OF_ALL)
  end

  def about
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end
end
