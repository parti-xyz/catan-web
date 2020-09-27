class Front::LabelsController < Front::BaseController
  def index
    authorize! :labels, current_group
    render layout: 'front/simple'
  end

  def create
    authorize! :labels, current_group

    label = Label.new(label_params)
    label.group = current_group
    if label.save
      flash[:notice] = I18n.t('activerecord.successful.messages.created')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to front_labels_path
  end

  def update
    authorize! :labels, current_group

    label = Label.find(params[:id])
    label.assign_attributes(label_params)

    if label.save
      flash[:notice] = I18n.t('activerecord.successful.messages.deleted')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to front_labels_path
  end

  def destroy
    authorize! :labels, current_group

    label = Label.find(params[:id])
    if label.destroy
      flash[:notice] = I18n.t('activerecord.successful.messages.deleted')
    else
      flash[:alert] = errors_to_flash(label)
    end

    turbolinks_redirect_to front_labels_path
  end

  private

  def label_params
    params.require(:label).permit(:title, :body)
  end
end