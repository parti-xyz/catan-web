class NotesController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show]
  load_and_authorize_resource

  def index
    @notes = Note.recent.page(params[:page])
  end

  def create
    redirect_to root_path and return if fetch_issue.blank?

    @note.user = current_user
    if !@note.save
      errors_to_flash(@note)
    end
    redirect_to params[:back_url].presence || issue_home_path(@issue)
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @note.issue
      notes_page
      @list_title = meta_issue_full_title(@issue)
      @list_url = issue_notes_path(@issue)
      @paginate_params = {controller: 'issues', :action => 'slug_notes', slug: @issue.slug, id: nil}
    end
    prepare_meta_tags title: @note.title
  end

  private

  def note_params
    params.require(:note).permit(:body)
  end

  def fetch_issue
    @issue ||= Issue.find_by id: params[:note][:issue_id]
    @note.issue = @issue.presence || @note.issue
  end
end
