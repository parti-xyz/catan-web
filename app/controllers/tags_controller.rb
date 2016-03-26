class TagsController < ApplicationController
  def show
    prepare_meta_tags title: params[:name],
                      description: params[:name]
    @posts = Post.recent.tagged_with(params[:name]).page params[:page]
    @postables = @posts.map &:postable
  end
end
