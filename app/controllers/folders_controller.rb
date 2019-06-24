class FoldersController < ApplicationController
  load_and_authorize_resource except: [:sort]

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
        redirect_to smart_issue_folders_path(@folder.issue)
      end
    end
  end

  def sort
    @issue = Issue.find_by(id: params[:issue_id])
    render_404 if @issue.blank?
    authorize! :sort_folders, @issue
    @folders = @issue.folders

    begin
      @error = false
      payload = JSON.parse(params[:payload])
      ActiveRecord::Base.transaction do
        (payload || []).each do |item|
          mark_seq(nil, item, 0, @issue)
        end
      end
    rescue Exception => e
      logger.error e.backtrace.join("\n")
      @error = true
    end
  end

  private

  def mark_seq(parent_folder, item, current_seq, issue)
    case item['item_type']
    when 'Folder'
      folder = Folder.find_by(id: item['item_id'], issue_id: issue.id)
      return current_seq if folder.blank?

      folder.folder_seq = current_seq
      folder.parent_id = parent_folder.id if parent_folder.present?
      current_seq += 1
      folder.save!

      (item['children'] || []).each do |child_item|
        current_seq = mark_seq(folder, child_item, current_seq, issue)
      end
    when 'Post'
      post = Post.find_by(id: item['item_id'])
      return current_seq if post.blank?
      if post.issue_id != issue.id
        post.folder_id = nil
        post.folder_seq = nil
      else
        post.folder_id = parent_folder.id if parent_folder.present?
        post.folder_seq = current_seq
        current_seq += 1
      end
      post.save!
    end

    current_seq
  end

  def folder_params
    params.require(:folder).permit(:title, :parent_id)
  end
end
