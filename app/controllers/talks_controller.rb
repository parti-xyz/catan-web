class TalksController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :poll_social_card]
  load_and_authorize_resource

  def index
    talks_page
  end

  def create
    redirect_to root_path and return if fetch_issue.blank?
    @talk.reference = @talk.reference.unify if @talk.reference
    @talk.user = current_user
    if @talk.save
      callback_after_creating_talk
    else
      errors_to_flash(@talk)
    end
    redirect_to params[:back_url].presence || issue_home_path_or_url(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    @talk.assign_attributes(talk_params.delete_if {|key, value| value.empty? })
    @talk.reference = @talk.reference.try(:unify)
    if @talk.save
      callback_after_updating_talk
      update_comments
      redirect_to @talk
    else
      errors_to_flash @talk
      render 'edit'
    end
  end

  def destroy
    @talk.destroy
    redirect_to issue_home_path_or_url(@talk.issue)
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @talk.issue
      @last_post = nil
      issus_posts = @issue.posts.order(last_touched_at: :desc)
      @posts = issus_posts.limit(25)
      current_last_post = @posts.last
      @is_last_page = (issus_posts.empty? or issus_posts.previous_of_post(current_last_post).empty?)
    end

    if @talk.poll.present?
      prepare_meta_tags title: @talk.meta_tag_title,
        description: '어떻게 생각하시나요?',
        image: poll_social_card_talk_url(format: :png),
        twitter_card_type: 'summary_large_image'
    else
      prepare_meta_tags title: @talk.meta_tag_title
    end
  end

  def poll_social_card
    respond_to do |format|
      format.png do
        if params[:no_cached]
          png = IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
          send_data(png, :type => "image/png", :disposition => 'inline')
        else
          @post = @talk.acting_as
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

  def postable_controller?
    true
  end

  private

  def update_comments
    return if params[:comment_body].blank?

    comment = Comment.find_by(id: params[:comment_id])
    return if comment.blank? or comment.user != current_user

    comment.update_attributes(body: params[:comment_body])
  end

  def talk_params
    reference_type = params[:talk][:reference_type]
    reference_attributes = reference_type.constantize.require_attrbutes if reference_type.present?
    poll = params[:talk][:poll_attributes]
    poll_attributes = [:title] if poll.present?
    params.require(:talk).permit(:body, :issue_id, :section_id, :reference_type, :has_poll,
      reference_attributes: reference_attributes, poll_attributes: poll_attributes)
  end

  def fetch_issue
    @issue ||= Issue.find_by id: params[:talk][:issue_id]
    @talk.issue = @issue.presence || @talk.issue
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @talk.acting_as.comments.build(body: body, user: current_user)
  end

  def callback_after_updating_talk
    if @talk.link_source?
      CrawlingJob.perform_async(@talk.reference.id)
    end
  end

  def callback_after_creating_talk
    if @talk.reference.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@talk.reference.id)
    end
  end
end
