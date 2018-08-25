class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update_wiki]
  before_action :authenticate_user!, except: [:index, :show, :wiki, :poll_social_card, :survey_social_card, :modal, :more_comments]
  load_and_authorize_resource
  before_action :set_current_history_back_post
  before_action :noindex_meta_tag, except: [:index ]

  include DashboardGroupHelper

  def index
    redirect_to root_path
  end

  def create
    if fetch_issue.blank? or private_blocked?(@issue)
      render_404 and return
    end

    if 'true' == params[:need_remotipart] and !remotipart_submitted?
      Rails.logger.info "DOUBLE REMOTIPART!!"
      head 200 and return
    end

    service = PostCreateService.new(post: @post, current_user: current_user)
    unless service.call
      errors_to_flash(@post)
    end

    if @post.errors.blank?
      flash[:success] = I18n.t('activerecord.successful.messages.created')
    end

    back_url = params[:back_url].presence || smart_issue_home_path_or_url(@issue)
    @current_issue = @post.issue if back_url == smart_issue_home_url(@issue)

    respond_to do |format|
      format.html {
        if @post.wiki.present?
          @post.wiki.reload
          redirect_to smart_post_url(@post)
        else
          redirect_to back_url
        end
      }
      format.js {
        # 이미지 로딩
        @post.reload
        render layout: nil
      }
    end
  end

  def update
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)
    @post.assign_attributes(post_params.delete_if {|key, value| value.empty? })
    @post.format_body

    @post.setup_link_source(@post.body_was)

    if @post.save
      crawling_after_updating_post
      @post.perform_mentions_async
      flash[:success] = I18n.t('activerecord.successful.messages.created')
      redirect_to params[:back_url].presence || smart_post_url(@post)
    else
      errors_to_flash @post
      render 'posts/edit'
    end
  end

  def wiki
    respond_to do |format|
      format.html { redirect_to smart_post_url(@post) }
      format.js
    end
  end

  def new_wiki
    if params[:issue_id].present?
      @issue = Issue.find_by id: params[:issue_id]
      render_404 and return if @issue.blank? or @issue.private_blocked?(current_user)
    end

    @post = Post.new
    @post.wiki = Wiki.new
    @post.issue = @issue
  end

  def update_wiki
    if fetch_issue.blank? or private_blocked?(@issue)
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render_404 }
      end
      return
    end

    render_404 and return if @post.wiki.blank?
    conflict = @post.wiki.wiki_histories.last.try(:id) != params[:last_wiki_history_id].try(:to_i)
    @list_url = smart_post_url(@post)

    @post.assign_attributes(wiki_post_params.delete_if {|key, value| value.empty? })

    if @post.wiki.changed?
      @post.wiki.format_body
      @post.strok_by(current_user)
      @post.wiki.last_author = @current_user

      if conflict
        @post.wiki.build_conflict
        respond_to do |format|
          format.html { render :show }
          format.js { render 'posts/update_wiki' }
        end
      elsif @post.save
        @post.issue.strok_by!(current_user, @post)
        flash[:success] = I18n.t('activerecord.successful.messages.created')
        respond_to do |format|
          format.html { redirect_to params[:back_url].presence || smart_post_url(@post) }
          format.js { render 'posts/update_wiki' }
        end
      else
        errors_to_flash @post
        respond_to do |format|
          format.html { render :show }
          format.js { render 'application/show_flash' }
        end
      end
    else
      flash[:success] = I18n.t('activerecord.successful.messages.created')
      respond_to do |format|
        format.html { redirect_to params[:back_url].presence || smart_post_url(@post) }
        format.js { render 'application/show_flash' }
      end
    end
  end

  def update_decision
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)

    conflict = (@post.decision_histories.any? and (@post.decision_histories.last.try(:id) != params[:last_decision_history_id].try(:to_i)))

    @post.assign_attributes(decision: params[:post][:decision])
    @post.strok_by(current_user, :decision)

    unless @post.will_save_change_to_decision?
      redirect_to(params[:back_url].presence || smart_post_url(@post)) and return
    end

    if conflict
      @post.build_conflict_decision
      render :edit_decision
    elsif @post.save
      @post.issue.strok_by!(current_user, @post)
      @decision_history = @post.decision_histories.create(body: @post.decision, user: current_user)
      DecisionNotificationJob.perform_async(current_user.id, @decision_history.id)

      flash[:success] = I18n.t('activerecord.successful.messages.created')
      redirect_to params[:back_url].presence || smart_post_url(@post)
    else
      errors_to_flash @post
      render edit_decision_post_path(@post)
    end
  end

  def decision_histories
    @history_page = @post.decision_histories.recent.page params[:page]
  end

  def destroy
    PostDestroyService.new(@post).call

    respond_to do |format|
      format.js
      format.html { redirect_to smart_issue_home_path_or_url(@post.issue) }
    end
  end

  def pin
    need_to_notification = @post.pinned_at.blank?
    @post.assign_attributes(pinned: true, last_stroked_at: DateTime.now, pinned_at: DateTime.now)
    @post.strok_by(current_user)
    @post.save!
    @post.issue.strok_by!(current_user, @post)
    PinJob.perform_async(@post.id, current_user.id) if need_to_notification
  end

  def unpin
    @post.update_attributes(pinned: false)
  end

  def read
    add_reader(@post)
  end

  def readers
    @issue = @post.issue
    @readers = @post.readers.recent.page(params[:page]).per(3 * 10)
    @reader_members = @post.issue.members.where(user_id: @readers.map(&:user_id))
  end

  def unreaders
    @issue = @post.issue

    base = @issue.members.where.not(user_id: @post.readers.select(:user_id)).recent
    @members = base.recent.page(params[:page]).per(3 * 10)
  end

  def show
    return unless verify_group(@post.issue)

    add_reader(@post) if @post.pinned?
    @issue = @post.issue
    @list_url = smart_post_url(@post)

    return if @post.private_blocked?(current_user)
    if @post.poll.present?
      prepare_meta_tags title: @post.issue.title,
        image: @post.meta_tag_image,
        description: "\"#{@post.meta_tag_description}\" 어떻게 생각하시나요?",
        twitter_card_type: 'summary_large_image'
    else
      prepare_meta_tags title: @post.meta_tag_title,
        image: @post.meta_tag_image,
        description: @post.meta_tag_description
    end
  end

  def poll_social_card
    social_card
  end

  def survey_social_card
    social_card
  end

  def more_comments
    render_404 and return unless request.format.js?
    if params[:parent_comment_id].present?
      @parent_comment = @post.comments.find_by(id: params[:parent_comment_id])
      render_404 and return if @parent_comment.blank?
      if params[:child_comment_id].present?
        @child_comment = @post.comments.find_by(id: params[:child_comment_id])
      end
    end
  end

  def edit
  end

  def move_to_issue_form
  end

  def move_to_issue
    issue_id = params[:post][:issue_id]
    render_404 and return if issue_id.blank?

    if @post.update_attributes(issue_id: issue_id, folder: nil)
      @post.upvotes.update_all(issue_id: issue_id)
      Upvote.where(upvotable: @post.comments).update_all(issue_id: issue_id)
    end

    redirect_to params[:back_url].presence || smart_post_url(@post)
  end

  def pinned
    if params[:group_slug].present?
      if params[:group_slug] == 'all'
        @dashboard_group = nil
        save_current_dashboard_group(nil)
      else
        @dashboard_group = Group.find_by(slug: params[:group_slug])
        save_current_dashboard_group(@dashboard_group)
      end
    else
      @dashboard_group = current_dashboard_group
    end

    if @dashboard_group.present?
      group_grouping_pinned_posts = { @dashboard_group => current_user.pinned_posts.where(issue: @dashboard_group.issues) }
    else
      group_grouping_pinned_posts = current_user.pinned_posts.to_a.group_by { |post| post.issue.group }
    end

    @pinned_posts = []
    Group.where(id: group_grouping_pinned_posts.keys).sort_by_name.each do |group|
      parti_grouping_pinned_posts = group_grouping_pinned_posts[group].to_a.group_by { |post| post.issue }
      Issue.where(id: parti_grouping_pinned_posts.keys).sort_by_name.each do |issue|
        @pinned_posts << [issue, parti_grouping_pinned_posts[issue]]
      end
    end
  end

  def edit_folder
  end

  def update_folder
    param_folder_id = params[:post][:folder_id]
    if param_folder_id.blank?
      @folder = nil
    elsif param_folder_id == "-1"
      @folder = Folder.new(title: params[:new_folder][:title], parent_id: params[:new_folder][:parent_id], issue: @post.issue)
    elsif param_folder_id == "-2"
      @folder = @post.folder
      render_404 and return if @folder.blank?

      @folder.update_attributes(title: params[:update_folder][:title], parent_id: params[:update_folder][:parent_id])
    else
      @folder = Folder.find_by(id: param_folder_id)
      render_404 and return if @folder.blank?

      if @post.issue != @folder.issue
        flash[:error] = t('errors.messages.folder.bad_issue')
        return
      end
    end

    @post.folder = @folder
    ActiveRecord::Base.transaction do
      if @folder.present? and !@folder.persisted?
        @folder.save
        errors_to_flash @folder
      end
      @post.save
      errors_to_flash @post
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def social_card
    render_404 and return if @post.private_blocked?

    respond_to do |format|
      format.png do
        if params[:no_cached]
          png = IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
          send_data(png, :type => "image/png", :disposition => 'inline')
        else
          if !@post.social_card.file.try(:exists?) or (params[:update] and current_user.try(:admin?))
            file = Tempfile.new(["social_card_#{@post.id.to_s}", '.png'], 'tmp', :encoding => 'ascii-8bit')
            file.write IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
            file.flush
            @post.social_card = file
            @post.save
            file.unlink
          end
          if @post.social_card.file.respond_to?(:url)
            data = open @post.social_card.url
            send_data data.read, filename: "social_card.png", :type => "image/png", disposition: 'inline', stream: 'true', buffer_size: '4096'
          else
            send_file(@post.social_card.path, :type => "image/png", :disposition => 'inline')
          end
        end
      end
      format.html { render(layout: nil) }
    end
  end

  def post_params
    file_sources = params[:post][:file_sources_attributes]
    if file_sources.try(:any?)
      file_sources_attributes = FileSource.require_attrbutes

      index = 0
      file_sources.each do |file_source|
        params[:post][:file_sources_attributes][file_source[0]]["seq_no"] = index
        index += 1
      end
    end

    poll = params[:post][:poll_attributes]
    poll_attributes = [:title, :duration_days, :hidden_intermediate_result, :hidden_voters] if poll.present?

    survey = params[:post][:survey_attributes]
    options_attributes = [:id, :body, :_destroy] unless @post.try(:survey).try(:persisted?)
    survey_attributes = [:duration_days, :multiple_select, :hidden_intermediate_result, :hidden_option_voters, options_attributes: options_attributes] if survey.present?

    wiki = params[:post][:wiki_attributes]
    wiki_attributes = [:id, :title, :body] if wiki.present?

    params.require(:post)
      .permit(:body, :issue_id, :has_poll, :has_survey, :is_html_body, :decision,
        file_sources_attributes: file_sources_attributes,
        poll_attributes: poll_attributes, survey_attributes: survey_attributes,
        wiki_attributes: wiki_attributes)
  end

  def wiki_post_params
    wiki = params[:post][:wiki_attributes]
    wiki_attributes = [:id, :title, :body, :is_html_body] if wiki.present?

    params.require(:post)
      .permit(:has_poll, :has_survey,
        wiki_attributes: wiki_attributes)
  end

  def set_current_user_to_options(post)
    (post.survey.try(:options) || []).each do |option|
      option.user = current_user
    end
  end

  def fetch_issue
    @issue ||= Issue.find_by id: params[:post][:issue_id]
    @post.issue = @issue.presence || @post.issue
    @issue = @post.issue
  end

  def crawling_after_updating_post
    if @post.link_source.present?
      CrawlingJob.perform_async(@post.link_source.id)
    end
  end

  def crawling_after_creating_post
    if @post.link_source.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@post.link_source.id)
    end
  end

  def private_blocked?(issue)
    return true if issue.blank?
    issue.private_blocked?(current_user)
  end

  def add_reader(post)
    return unless user_signed_in?
    member = post.issue.members.find_by(user: current_user)
    return if member.blank?

    post.readers.find_or_create_by(user: member.user)
  end

  def set_current_history_back_post
    @current_history_back_post = @post
  end

  def noindex_meta_tag
    if current_group.present? and current_group.private?
      set_meta_tags noindex: true
      return
    end

    if @post.present? and @post.issue.try(:private?)
      set_meta_tags noindex: true
      return
    end
  end
end
