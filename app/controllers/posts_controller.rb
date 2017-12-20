class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :wiki, :poll_social_card, :survey_social_card, :modal]
  load_and_authorize_resource

  def index
    redirect_to root_path
  end

  def create
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)

    service = PostCreateService.new(post: @post, current_user: current_user)
    unless service.call
      errors_to_flash(@post)
    end

    if @post.wiki.present? and @post.errors.blank?
      flash[:success] = I18n.t('activerecord.successful.messages.created')
      @post.wiki.reload
      redirect_to smart_wiki_url(@post.wiki)
    else
      redirect_to params[:back_url].presence || smart_issue_home_path_or_url(@issue)
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
      redirect_to params[:back_url].presence || @post
    else
      errors_to_flash @post
      render 'edit'
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

  def wiki
    @issue = @post.issue
    verify_group(@issue)

    render_404 and return if @post.wiki.blank?
  end

  def update_wiki
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)
    render_404 and return if @post.wiki.blank?

    @post.assign_attributes(wiki_post_params.delete_if {|key, value| value.empty? })
    if @post.wiki.changed?
      @post.wiki.format_body
      @post.strok_by(current_user)
      @post.wiki.last_author = @current_user
      if @post.save
        @post.issue.strok_by!(current_user, @post)
        flash[:success] = I18n.t('activerecord.successful.messages.created')
        redirect_to params[:back_url].presence || smart_wiki_url(@post.wiki)
      else
        errors_to_flash @post
        render :wiki
      end
    else
      flash[:success] = I18n.t('activerecord.successful.messages.created')
      redirect_to params[:back_url].presence || smart_wiki_url(@post.wiki)
    end
  end

  def update_decision
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)

    @post.assign_attributes(decision: params[:post][:decision])
    @post.strok_by(current_user, :decision)

    unless @post.decision_changed?
      redirect_to(params[:back_url].presence || @post) and return
    end

    if @post.save
      @post.issue.strok_by!(current_user, @post)
      @decision_history = @post.decision_histories.create(body: @post.decision, user: current_user)
      DecisionMailer.deliver_all_later_on_update(current_user, @decision_history)

      flash[:success] = I18n.t('activerecord.successful.messages.created')
      redirect_to params[:back_url].presence || @post
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
  end

  def unreaders
    @issue = @post.issue

    base = @issue.members.where.not(id: @post.readers.select(:member_id)).recent
    @members = base.recent.page(params[:page]).per(3 * 10)
  end

  def show
    add_reader(@post) if @post.pinned?
    verify_group(@post.issue)
    @issue = @post.issue

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

  def images
    @issue = @post.issue
    prepare_meta_tags title: @post.meta_tag_title,
      image: @post.meta_tag_image,
      description: @post.meta_tag_description
  end

  def poll_social_card
    social_card
  end

  def survey_social_card
    social_card
  end

  def more_comments
  end

  def edit
    redirect_to smart_wiki_url(@post.wiki) and return if @post.wiki.present?
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

      file_sources.to_a.each_with_index do |file_source, index|
        params[:post][:file_sources_attributes][file_source[0]]["seq_no"] = index
      end
    end

    poll = params[:post][:poll_attributes]
    poll_attributes = [:title] if poll.present?

    survey = params[:post][:survey_attributes]
    options_attributes = [:id, :body, :_destroy] unless @post.try(:survey).try(:persisted?)
    survey_attributes = [:duration_days, :multiple_select, options_attributes: options_attributes] if survey.present?

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

    post.readers.find_or_create_by(member: member)
  end
end
