class PostsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :poll_social_card, :survey_social_card, :modal]
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
    redirect_to params[:back_url].presence || smart_issue_home_path_or_url(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank? or private_blocked?(@issue)
    @post.assign_attributes(post_params.delete_if {|key, value| value.empty? })
    @post.format_body

    setup_link_source(@post)

    if @post.save
      crawling_after_updating_post
      @post.perform_mentions_async
      redirect_to params[:back_url].presence || @post
    else
      errors_to_flash @post
      render 'edit'
    end
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
    @post.issue.strok_by!(current_user)
    PinJob.perform_async(@post.id, current_user.id) if need_to_notification
  end

  def unpin
    @post.update_attributes(pinned: false)
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

  def modal
    @post = Post.find(params[:id])
  end

  def show
    add_reader(@post) if @post.pinned?
    verify_group(@post.issue)
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @post.issue
    end

    return if @post.private_blocked?(current_user)
    if !@post.blinded?(current_user)
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

    params.require(:post)
      .permit(:body, :issue_id, :has_poll, :has_survey, :is_html_body,
        file_sources_attributes: file_sources_attributes, poll_attributes: poll_attributes, survey_attributes: survey_attributes)
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

  def setup_link_source(post)
    if post.survey.blank? and post.poll.blank? and post.file_sources.blank? and post.body.present?
      old_link = nil
      if post.link_source.present?
        old_link = post.link_source.url
      end

      links = find_all_a_tags(post.body)
      links_was = find_all_a_tags(post.body_was)

      first_link = links.first
      if first_link.present? and first_link['href'].present?
        if post.link_source.try(:url) != first_link['href']
          encoding_options = {
            :invalid           => :replace,  # Replace invalid byte sequences
            :undef             => :replace,  # Replace anything not defined in ASCII
            :replace           => '',        # Use a blank for those replacements
            :universal_newline => true       # Always break lines with \n
          }
          post.link_source = LinkSource.new(url: first_link['href'].encode(Encoding.find('ASCII'), encoding_options))
        end
      else
        if old_link.present?
          if !links.map{ |l| l['href'] }.include?(old_link) and links_was.map{ |l| l['href'] }.include?(old_link)
            post.link_source = nil
          else
            post.body += "<p><a href='#{old_link}'>#{old_link}</a></p>"
          end
        end
      end
    end
    post.link_source = post.link_source.unify if post.link_source.present?
  end

  def find_all_a_tags(body)
    Nokogiri::HTML.parse(body).xpath('//a[@href]').reject{ |p| all_child_nodes_are_blank?(p) }
  end

  def is_blank_node?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_child_nodes_are_blank?(node)
    node.children.all?{ |child| is_blank_node?(child) }
  end
end
