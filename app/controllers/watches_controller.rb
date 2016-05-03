class WatchesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :issue
  load_and_authorize_resource :watch, through: :issue, shallow: true

  def create
    @watch.user = current_user
    @watch.save

    respond_to do |format|
      format.js
      format.html { redirect_to issue_home_path(@issue) }
    end
  end

  def cancel
    @watch = @issue.watches.find_by user: current_user
    @watch.destroy if @watch.present?

    respond_to do |format|
      format.js
      format.html { redirect_to issue_home_path(@issue) }
    end
  end
end
