class Front::PostsController < Front::BaseController
  def show
    @current_post = Post.includes(:user, :survey, :current_user_post_reader, :current_user_bookmark, :current_user_upvotes, :last_stroked_user, :file_sources, :label, issue: [:group], announcement: [ current_user_audience: [ :member ] ], user: [ :current_group_member ], comments: [ :parent, :wiki_history, :file_sources, :current_user_bookmark, :current_user_upvotes, user: [ :current_group_member ] ], wiki: [ :last_wiki_history, wiki_authors: [ :user ] ], poll: [ :current_user_voting ])
      .find(params[:id])

    @current_issue = Issue.includes(:group, :folders, :current_user_issue_reader, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    params_wiki_history_id = params[:wiki_history_id]

    if @current_post.wiki.present? && params_wiki_history_id.present?
      @current_wiki_history = @current_post.wiki.wiki_histories.find_by(id: params_wiki_history_id)
    end

    @supplementary_locals = prepare_post_supplementary(@current_post, params_wiki_history_id)

    if user_signed_in?
      @current_post.read!(current_user)
      @current_issue.read!(current_user)
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"

    if @current_post.stroked_post_users.empty?
      StrokedPostUserJob.perform_async(@current_post.id)
    end
  end

  def new
    render_403 and return unless user_signed_in?
    @current_issue = Issue.includes(:folders, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(params[:issue_id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.find_by(id: params[:folder_id])

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def edit
    render_403 and return unless user_signed_in?

    @current_post = Post
      .includes(:user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, announcement: [:current_user_audience], issue: [ :folders ], comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])
    authorize! :update, @current_post

    @current_issue = Issue.includes(:folders, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_post_supplementary(@current_post)
  end

  def edit_wiki
    render_403 and return unless user_signed_in?

    @current_post = Post
      .includes(:user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, announcement: [:current_user_audience], issue: [ :folders ], comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])
    authorize! :update_wiki, @current_post
    render_404 and return if @current_post.wiki.blank?

    @current_issue = Issue.includes(:folders, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_post_supplementary(@current_post)
  end

  def edit_title
    render_403 and return unless user_signed_in?

    @current_post = Post.includes(:label, :issue).find(params[:id])
    authorize! :front_update_title, @current_post

    render layout: nil
  end

  def update_title
    render_403 and return unless user_signed_in?

    @current_post = Post.includes(:label, :wiki).find(params[:id])
    authorize! :front_update_title, @current_post

    if current_user != @current_post.user
      @current_post.last_title_edited_user = current_user
    end

    @current_post.base_title = params[:post][:base_title]
    @current_post.label_id = params[:post][:label_id]
    if @current_post.save
      @current_post.read!(current_user)
      @current_post.issue.read!(current_user)

      flash.now[:notice] = I18n.t('activerecord.successful.messages.created')
    else
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    render layout: nil
  end

  def transfer_wiki
    @current_post = Post.includes(:label, :wiki).find(params[:id])
    authorize! :transfer_wiki, @current_post

    if @current_post.wiki.present?
      turbolinks_redirect_to edit_front_post_path(@current_post)
      return
    end

    @current_post.build_wiki(last_author: @current_post.user, body: @current_post.body, force_created_at: @current_post.created_at)
    @current_post.body = nil
    if @current_post.save
      flash[:notice] = I18n.t('activerecord.successful.messages.created')
      turbolinks_redirect_to edit_wiki_front_post_path(@current_post)
    else
      abort @current_post.errors.inspect
      flash[:alert] = I18n.t('errors.messages.unknown')
      turbolinks_redirect_to smart_front_post_url(@current_post)
    end
  end

  def update_announcement
    render_403 and return unless user_signed_in?

    @current_post = Post.includes(:label, :announcement).find(params[:id])
    authorize! :announce, @current_post.issue

    result = false
    ActiveRecord::Base.transaction do
      if @current_post.announcement.blank?
        @current_post.announcement = Announcement.create(post: @current_post)
        result = @current_post.save
        raise ActiveRecord::Rollbacks unless result

        SendMessage.run(source: @current_post.announcement, sender: current_user, action: :create_announcement)
      end

      if @current_post.announcement.requested_to_notice?(current_user)
        NoticeAnnouncement.run(current_group: current_group, current_user: current_user, announcement: @current_post.announcement)
      end
    end

    if result
      flash[:notice] = '필독 요청되었습니다'
    else
      flash[:alert] = I18n.t('errors.messages.unknown')
    end

    turbolinks_redirect_to smart_front_post_url(@current_post)
  end

  def update_label
    render_403 and return unless user_signed_in?

    @current_post = Post.find(params[:id])
    authorize! :front_update_label, @current_post

    @current_post.label_id = params[:label_id]
    if @current_post.save
      @current_post.read!(current_user)
      @current_post.issue.read!(current_user)

      flash.now[:notice] = I18n.t('activerecord.successful.messages.created')
    else
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    head 204
  end

  def cancel_title_form
    @current_post = Post.includes(:label, :wiki).find(params[:id])
    authorize! :front_update_title, @current_post

    render layout: nil
  end

  def destroyed
    @current_post = Post.only_deleted.find(params[:id])

    @current_issue = Issue.includes(:posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def edit_channel
    @current_post = Post.includes(:issue).find(params[:id])
    authorize! :move_to_issue, @current_post

    @issues = current_group.issues.includes(:category).sort_default

    render layout: nil
  end

  def update_channel
    issue_id = params[:post][:issue_id]
    render_404 and return if issue_id.blank?

    @current_post = Post.includes(:issue).find(params[:id])
    authorize! :move_to_issue, @current_post

    redirect_back(fallback_location: smart_front_post_url(@current_post)) and return if @current_post.issue_id.to_s == issue_id.strip

    @current_post.assign_attributes(issue_id: issue_id, folder: nil)

    if @current_post.save
      @current_post.upvotes.update_all(issue_id: issue_id)
      Upvote.where(upvotable: @current_post.comments).update_all(issue_id: issue_id)

      flash[:notice] = I18n.t('activerecord.successful.messages.completed')
    else
      flash[:alert] = I18n.t('errors.messages.unknown')
    end

    turbolinks_redirect_to smart_front_post_url(@current_post)
  end
end
