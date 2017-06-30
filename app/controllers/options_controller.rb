class OptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @option = Option.new(options_params)
    if @option.body.blank?
      return
    end

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user) or !@post.issue.member?(current_user)
      render_404 and return
    end

    OptionSurveyService.new(option: @option, current_user: current_user).create
  end

  def destroy
    @option = Option.find(params[:id])

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    @option.destroy! if @option.user == current_user
  end

  private

  def options_params
    params.require(:option).permit(:survey_id, :body)
  end
end
