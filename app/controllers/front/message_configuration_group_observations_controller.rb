class Front::MessageConfigurationGroupObservationsController < Front::BaseController
  def create
    render_403 and return unless current_group.member?(current_user)

    group_observation = MessageConfiguration::GroupObservation.of(current_user, current_group)
    group_observation.inherit_payoffs
    group_observation.assign_attributes(permitted_params)
    group_observation.save!

    head(204)
  end

  def update
    group_observation = MessageConfiguration::GroupObservation.of(current_user, current_group)
    authorize! :update, group_observation

    group_observation.update_attributes!(permitted_params)

    head(204)
  end

  private

  def permitted_params
    params.require(:message_configuration_group_observation).permit(MessageObservationConfigurable.all_payoff_column_names_permitted)
  end
end