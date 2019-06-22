class FoldersController < ApplicationController
  load_and_authorize_resource

  def destroy
    unless @folder.destroy
      errors_to_flash @folder
    end

    if params[:back_url].present?
      redirect_to params[:back_url]
    else
      redirect_to smart_issue_folders_path(@folder.issue)
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    unless @folder.update_attributes(folder_params)
      errors_to_flash(@folder)
    end

    if request.xhr?
      render
    else
      if params[:back_url].present?
        redirect_to params[:back_url]
      else
        redirect_to smart_folder_url(@folder)
      end
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:title, :parent_id)
  end
end
