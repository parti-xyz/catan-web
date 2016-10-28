class PollsController < ApplicationController
  load_and_authorize_resource

  def index
    having_poll_talks_page
  end
end
