class RedirectsController < ApplicationController
  def opinion
    talk_id = OpinionToTalk.find_by!(opinion_id: params[:id]).try(:talk_id)
    post = Post.find_by!(postable_type: 'Talk', postable_id: talk_id)
    redirect_to smart_post_url(post)
  end

  def talk
    post = Post.find_by!(postable_type: 'Talk', postable_id: params[:id])
    redirect_to smart_post_url(post)
  end
end
