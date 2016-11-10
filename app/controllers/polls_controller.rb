class PollsController < ApplicationController
  load_and_authorize_resource

  def index
    having_poll_posts_page
  end
end
