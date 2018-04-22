class FoldersController < ApplicationController
  load_and_authorize_resource

  def create
    @folder.user = current_user
    unless @folder.save
      errors_to_flash @folder
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    unless @folder.destroy
      errors_to_flash @folder
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:title, :issue_id)
  end
end
