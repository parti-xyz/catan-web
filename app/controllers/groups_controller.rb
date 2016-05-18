class GroupsController < ApplicationController
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    @group.user = current_user
    if @group.save
      redirect_to @group
    else
      render 'new'
    end
  end

  def slug_show
    @slug = params[:slug]
    if @slug.present?
      @group = Group.find_by slug: @slug
      if @group.present?
        redirect_to @group and return
      end
    end

    redirect_to root_path
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to @group
    else
      render 'edit'
    end
  end

  def destroy
    @group.destroy
    redirect_to root_path
  end

  def add_parti
    @issue = Issue.find_by slug: params[:issue_slug]
    if @issue.present?
      @issue.group = @group
      @issue.save
    end

    redirect_to parties_group_path(@group)
  end

  def remove_parti
    @issue = Issue.find_by id: params[:issue_id]
    if @issue.present? and @group.issues.exists?(@issue.id)
      @issue.group = nil
      @issue.save
    end

    redirect_to parties_group_path(@group)
  end

  private

  def group_params
    params.require(:group).permit(:title, :body, :logo, :cover, :slug)
  end
end
