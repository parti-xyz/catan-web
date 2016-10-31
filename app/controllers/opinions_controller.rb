class OpinionsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :social_card]
  load_and_authorize_resource

  def index
    redirect_to polls_path
  end

  def create
    set_issue
    redirect_to root_path and return if @issue.blank?

    @opinion.user = current_user
    if @opinion.save
      set_comment
      set_vote
    end

    redirect_to params[:back_url].presence || issue_home_path_or_url(@issue)
  end

  def update
    set_issue
    if @opinion.update_attributes(update_params)
      redirect_to @opinion
    else
      errors_to_flash @opinion
      render 'edit'
    end
  end

  def destroy
    @opinion.destroy
    redirect_to issue_home_path_or_url(@opinion.issue)
  end

  def show
    redirect_destination = OpinionToTalk.where(opinion_id: params[:id]).first.talk_id
    redirect_to talk_path(redirect_destination)
  end

  def social_card
    respond_to do |format|
      format.png do
        if params[:no_cached]
          png = IMGKit.new(render_to_string(layout: nil), width: 1200, height: 630, quality: 10).to_png
          send_data(png, :type => "image/png", :disposition => 'inline')
        else
          @post = @opinion.acting_as
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

  private

  def set_comment
    body = params[:comment_body]
    if body.present?
      @comment = @opinion.post.comments.create(user: current_user, body: body, choice: :agree)
    end
  end

  def set_vote
    @vote = @opinion.post.votes.create(user: current_user, choice: :agree)
  end

  def create_params
    params.require(:opinion).permit(:title, :body, :issue_id)
  end

  def update_params
    params.require(:opinion).permit(:title)
  end

  def set_issue
    @issue ||= Issue.find_by id: params[:opinion][:issue_id]
    @opinion.issue = @issue.presence || @opinion.issue
  end
end
