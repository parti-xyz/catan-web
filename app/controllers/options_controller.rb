class OptionsController < ApplicationController
  before_action :authenticate_user!
  # TODO remote
  def create
    @option = Option.new(options_params)
    @option.user = current_user

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    @option.save! if survey.open?
  end

  def destroy
    @option = Option.find(params[:id])

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    @option.destroy!
  end

  private

  def options_params
    params.require(:option).permit(:survey_id, :body)
  end
end
