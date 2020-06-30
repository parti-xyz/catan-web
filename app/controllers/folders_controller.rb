class FoldersController < ApplicationController
  load_and_authorize_resource except: [:sort]

  def create
    authorize! :manage_folders, @folder.issue
    @folder.save
    errors_to_flash @folder

    @issue = @folder.issue
    @folders = @issue.folders

    respond_to do |format|
      format.js
    end
  end

  def destroy
    unless @folder.destroy
      errors_to_flash @folder
    end

    respond_to do |format|
      format.html do
        if params[:back_url].present?
          redirect_to params[:back_url]
        else
          redirect_to smart_issue_folders_path(@folder.issue)
        end
      end
      format.js do
        @issue = @folder.issue
        @folders = @issue.folders
      end
    end
  end

  def new
    @issue = Issue.find_by(id: params[:issue_id])
    render_404 and return if @issue.blank?
    authorize! :manage_folders, @issue

    if @issue.present?
      @parent_folder = @issue.folders.find_by(id: params[:parent_folder_id])
    else
      @parent_folder = Folder.find_by(id: params[:parent_folder_id])
      @issue = @folder.issue
    end
    render_404 and return if Folder.safe_id(params[:parent_folder_id]) != Folder::ROOT_ID and @parent_folder.blank?
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    unless @folder.update_attributes(update_params)
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
    render_404 and return if @issue.blank? or params[:item_type].blank?
    @current_instance = params[:item_type].safe_constantize.try(:find_by, {id: params[:item_id]})
    render_404 and return if @current_instance.blank?

    authorize! :manage_folders, @issue
    @folders = @issue.folders

    begin
      @error = false
      payload = JSON.parse(params[:payload])
    rescue Exception => e
      logger.error e.backtrace.join("\n")
      @error = true
      return
    end

    case params['item_type']
    when "Folder"
      if @current_instance.siblings.exists?(folder_seq: 0)
        @current_instance.siblings.to_a.sort_by{ |folder| Folder.compare_keys(folder) }.each_with_index do |folder, index|
          if folder.folder_seq != index + 1
            folder.update_columns(folder_seq: index + 1)
          end
        end
      end
    when "Post"
      if @current_instance.folder.posts.exists?(folder_seq: 0)
        @current_instance.folder.posts.order_by_folder_seq.to_a.each_with_index do |post, index|
          if post.folder_seq != index + 1
            post.update_columns(folder_seq: index + 1)
          end
        end
      end
    end

    result = mark_seq(nil, (payload || []), @issue, @current_instance)
    if result.nil?
      @error = true
    end
  end

  def attach_post
    @post = Post.find(params[:post_id])
    @issue = @post.issue
    @folder = Folder.find_by(id: params[:id])
    render_404 and return if @folder.blank?
    render_403 and return if @post.issue_id != @folder.issue_id

    @post.folder = @folder
    @post.folder_seq = (params[:folder_seq] || 0)
    @post.save

    respond_to do |format|
      format.js
    end
  end

  def detach_post
    @post = Post.find(params[:post_id])
    @issue = @post.issue
    @folder = Folder.find_by(id: params[:id])
    return if @folder.blank?
    return if @post.folder != @folder

    @post.folder = nil
    @post.folder_seq = 0
    @post.save
    respond_to do |format|
      format.js
    end
  end

  def new_post_form
    @issue = Issue.find_by(id: params[:issue_id])
    render_404 and return if @issue.blank?

    @target_parent_folder = if params[:parent_folder_id].present?
      if params[:parent_folder_id].to_i == Folder::ROOT_ID
        nil
      else
        Folder.find(params[:parent_folder_id])
      end
    else
      nil
    end

    @target_folders = if @target_parent_folder.present?
      @target_parent_folder.children
    else
      Folder.only_top.where(issue_id: @issue.id)
    end
    @target_folders = @target_folders.sort_by_default
  end

  def move_form
    @subject = params[:subject_type].safe_constantize.try(:find_by, {id: params[:subject_id]})
    render_404 and return if @subject.blank?

    @target_parent_folder = if params[:parent_folder_id].present?
      if params[:parent_folder_id].to_i == Folder::ROOT_ID
        nil
      else
        Folder.find(params[:parent_folder_id])
      end
    else
      if params[:subject_type] == 'Post'
        @subject.folder
      else
        @subject.parent
      end
    end

    @target_folders = if @target_parent_folder.present?
      @target_parent_folder.children
    else
      Folder.only_top.where(issue_id: @subject.issue_id)
    end
    @target_folders = @target_folders.sort_by_default
  end

  def move
    @subject = params[:subject_type].safe_constantize.try(:find_by, {id: params[:subject_id]})
    render_404 and return if @subject.blank?
    @issue = @subject.issue

    parent_id = if params[:parent_id].try(:to_s) == '0'
      nil
    else
      parent_folder = Folder.find params[:parent_id]
      parent_folder.id
    end

    if params[:subject_type] == 'Post'
      @post = @subject
      unless @post.update_attributes(folder_id: parent_id)
        errors_to_flash(@post)
      end
    else
      @folder = @subject
      unless @folder.update_attributes(parent_id: parent_id)
        errors_to_flash(@folder)
      end
    end
  end

  private

  def mark_seq(parent_folder_item, items, issue, current_instance)
    parent_folder_id = parent_folder_item.try(:fetch, 'item_id')

    current_index = items.index do |item|
      item['item_type'] == current_instance.class.name and item['item_id'] == current_instance.id
    end

    if current_index.present?
      current_item = items[current_index]

      upper_index = current_index - 1
      upper_instance = nil
      while upper_index >= 0 and upper_instance.blank? do
        upper_item = items[upper_index]
        upper_index -= 1

        next if upper_item['item_type'] != current_item['item_type']

        upper_instance = (upper_item['item_type']).safe_constantize.try(:find_by, {id: upper_item['item_id'], "#{parent_folder_column(current_item)}": parent_folder_id})
      end

      current_seq = if upper_instance.present?
        upper_instance.folder_seq + 1
      else
        downer_index = current_index + 1
        downer_instance = nil
        while downer_index < items.length and downer_instance.blank? do
          downer_item = items[downer_index]
          downer_index += 1

          next if downer_item['item_type'] != current_item['item_type']

          downer_instance = (downer_item['item_type']).safe_constantize.try(:find_by, {id: downer_item['item_id'], "#{parent_folder_column(current_item)}": parent_folder_id})
        end
        downer_instance.try(:folder_seq) || items.length + 1
      end

      ActiveRecord::Base.transaction do
        parent_folder_column = nil

        case current_item['item_type']
        when "Folder"
          current_instance.parent_id = parent_folder_id
          current_instance.folder_seq = current_seq
        when "Post"
          current_instance.folder_id = parent_folder_id
          current_instance.folder_seq = current_seq
        end
        current_instance.save
        if current_instance.errors.any?
          errors_to_flash(current_instance)
          return nil
        end
        follow_items = issue.send(:"#{current_item['item_type'].underscore.pluralize}").where(parent_folder_column(current_item) => parent_folder_id).where('folder_seq >= ?', current_seq).where.not(id: current_instance.id).order(folder_seq: :asc).to_a
        follow_items.each_with_index do |follow_item, index|
          follow_item.folder_seq = current_seq + 1 + index
          follow_item.save
          if follow_item.errors.any?
            errors_to_flash(follow_item)
            return nil
          end
        end
      end

      return true
    else
      items.each do |item|
        if item['item_type'] == 'Folder' and item['children'].present?
          result = mark_seq(item, item['children'], issue, current_instance)
          if result.nil?
            return nil
          elsif  result == true
            return true
          end
        end
      end

      return false
    end
  end

  def parent_folder_column(item)
    case item['item_type']
    when "Folder"
      parent_folder_column = "parent_id"
    when "Post"
      parent_folder_column = "folder_id"
    end
  end

  def update_params
    params.require(:folder).permit(:title, :parent_id)
  end

  def create_params
    params.require(:folder).permit(:title, :parent_id, :issue_id)
  end
end
