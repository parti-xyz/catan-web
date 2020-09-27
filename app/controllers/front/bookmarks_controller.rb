class Front::BookmarksController < Front::BaseController
  load_and_authorize_resource :bookmark

  def index
    render_404 and return unless user_signed_in?

    all_bookmarks = current_user.bookmarks.of_group(current_group)

    base_bookmark = all_bookmarks
    @bookmarks = base_bookmark.includes(:user, :bookmarkable).recent.page(params[:page]).load

    @all_bookmarks_total_count = all_bookmarks.count
  end

  TEMPLATES = {
    'form' => '/front/bookmarks/form',
    'reaction' => '/front/bookmarks/reaction'
  }

  def create
    render_404 and return unless TEMPLATES.key?(params[:for])

    @bookmark = Bookmark.find_by(user: current_user, bookmarkable: @bookmark.bookmarkable).presence || @bookmark
    if @bookmark.persisted?
      flash.now[:notice] = '북마크했습니다.'
    else
      @bookmark.user = current_user
      if @bookmark.save
        flash.now[:notice] = '북마크했습니다.'
      else
        errors_to_flash(@bookmark)
      end
    end

    render(partial: TEMPLATES[params[:for]], locals: { bookmarkable: @bookmark.bookmarkable, bookmark: @bookmark })
  end

  def destroy
    render_404 and return unless TEMPLATES.key?(params[:for])

    @bookmark = Bookmark.find_by(user: current_user, bookmarkable: @bookmark.bookmarkable)

    if @bookmark.blank? || @bookmark.destroy
      flash.now[:notice] = '북마크 취소했습니다.'
    else
      errors_to_flash(@bookmark)
    end

    render(partial: TEMPLATES[params[:for]], locals: { bookmarkable: @bookmark.bookmarkable, bookmark: @bookmark })
  end

  private

  def bookmark_params
    params.require(:bookmark).permit(:bookmarkable_id, :bookmarkable_type)
  end
end
