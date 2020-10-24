class Front::MessageConfigurationPostObservationsController < Front::BaseController
  def create
    render_403 and return unless current_group.member?(current_user)

    current_post = Post.find(params[:post_id])
    post_observation = MessageConfiguration::PostObservation.of(current_user, current_post)
    post_observation.inherit_payoffs
    Rails.logger.debug post_observation.all_configurations.inspect
    post_observation.save

    render(partial: 'front/posts/supplementary/message_configurations_body', locals: { current_post: current_post })
  end

  def update
    post_observation = MessageConfiguration::PostObservation.find(params[:id])
    authorize! :update, post_observation

    post_observation.update_attributes!(update_params)

    head(204)
  end

  def destroy
    current_post = Post.find(params[:post_id])

    post_observation = MessageConfiguration::PostObservation.find_by(id: params[:id])

    post_observation.destroy! if post_observation.present? && post_observation.persisted?

    render(partial: 'front/posts/supplementary/message_configurations_body', locals: { current_post: current_post })
  end

  private

  def update_params
    params.require(:message_configuration_post_observation).permit(MessageObservationConfigurable.all_payoff_column_names_permitted)
  end
end