class GroupsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def create
    @group.user = current_user
    if @group.save
      redirect_to @group
    else
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to @group
    else
      render 'edit'
    end
  end

  def parties
  end

  private

  def group_params
    params.require(:group).permit(:title, :body, :logo, :cover, :slug)
  end
end
