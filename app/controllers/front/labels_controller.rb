class Front::LabelsController < Front::BaseController
  def create
    render_403 and return unless user_signed_in?

    current_issue = Issue.find(params[:label][:issue_id])
    authorize! :labels, current_issue

    label = Label.new(label_params)
    if label.save
      flash[:notice] = I18n.t('activerecord.successful.messages.created')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to labels_front_channel_path(current_issue)
  end

  def update
    render_403 and return unless user_signed_in?

    label = Label.find(params[:id])
    label.assign_attributes(label_params)

    current_issue = label.issue
    authorize! :labels, current_issue

    if label.save
      flash[:notice] = I18n.t('activerecord.successful.messages.deleted')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to labels_front_channel_path(current_issue)
  end

  def destroy
    render_403 and return unless user_signed_in?

    label = Label.find(params[:id])

    current_issue = label.issue
    authorize! :labels, current_issue

    if label.destroy
      flash[:notice] = I18n.t('activerecord.successful.messages.deleted')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to labels_front_channel_path(current_issue)
  end

  private

  def label_params
    params.require(:label).permit(:title, :body, :issue_id)
  end
end