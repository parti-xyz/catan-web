class FoldersController < ApplicationController
  load_and_authorize_resource

  def destroy
    unless @folder.destroy
      errors_to_flash @folder
    end

    redirect_to smart_issue_folders_path(@folder.issue)
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

    redirect_to smart_folder_url(@folder)
  end

  private

  def folder_params
    params.require(:folder).permit(:title, :parent_id)
  end
end
