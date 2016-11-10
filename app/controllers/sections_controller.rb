class SectionsController < ApplicationController
  before_filter :authenticate_user!, only: [:create]
  load_and_authorize_resource :issue
  load_and_authorize_resource through: :issue, shallow: true

  def create
    if @section.save
      redirect_to issue_posts_path(@issue)
    else
      errors_to_flash(@section)
      render 'new'
    end
  end

  def edit
    @issue = @section.issue
  end

  def update
    @issue = @section.issue
    if @section.update_attributes(section_params)
      redirect_to issue_posts_path(@issue)
    else
      errors_to_flash(@section)
      render 'edit'
    end
  end

  def destroy
    @issue = @section.issue
    if @section.initial?
      flash[:notice] = t('activerecord.errors.models.section.attributes.initial.undeletable')
    else
      ActiveRecord::Base.transaction do
        if @section.posts.any?
          initial_section = @issue.initial_section
          @section.posts.move_to(initial_section)
        end
        if !@section.destroy
          errors_to_flash(@section)
        end
      end
    end

    redirect_to issue_posts_path(@issue)
  end

  private

  def section_params
    params.require(:section).permit(:name)
  end
end
