class LinksAndFilesController < ApplicationController
  def index
    having_link_or_file_posts_page
  end
end

