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

    if helpers.explict_front_namespace?
      flash.now[:notice] = '제안을 추가했습니다'
      render(partial: '/front/posts/show/survey', locals: { survey: survey })
    end
  end

  def destroy
    @option = Option.find(params[:id])

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    @option.destroy! if @option.user == current_user

    if helpers.explict_front_namespace?
      flash.now[:notice] = '제안을 삭제했습니다'
      render(partial: '/front/posts/show/survey', locals: { survey: survey })
    end
  end

  def cancel
    @option = Option.find(params[:id])

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    if @option.user == current_user
      @option.canceled_at = DateTime.now
      @option.save
    end

    if helpers.explict_front_namespace?
      flash.now[:notice] = '제안을 취소했습니다'
      render(partial: '/front/posts/show/survey', locals: { survey: survey })
    end
  end

  def reopen
    @option = Option.find(params[:id])

    survey = @option.survey
    @post = Post.find_by survey: survey
    if @post.blank? or @post.private_blocked?(current_user)
      render_404 and return
    end

    if @option.user == current_user
      @option.canceled_at = nil
      @option.save
    end

    if helpers.explict_front_namespace?
      flash.now[:notice] = '제안을 재개했습니다'
      render(partial: '/front/posts/show/survey', locals: { survey: survey })
    end
  end

  private

  def options_params
    params.require(:option).permit(:survey_id, :body)
  end
end
