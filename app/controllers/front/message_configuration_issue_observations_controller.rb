class Front::MessageConfigurationIssueObservationsController < Front::BaseController
  def create
    render_403 and return unless current_group.member?(current_user)

    current_issue = Issue.find(params[:issue_id])
    issue_observation = MessageConfiguration::IssueObservation.of(current_user, current_issue)
    issue_observation.inherit_payoffs
    issue_observation.save

    render(partial: 'front/channels/supplementary/message_configurations_body', locals: { current_issue: current_issue })
  end

  def update
    issue_observation = MessageConfiguration::IssueObservation.find(params[:id])
    authorize! :update, issue_observation

    issue_observation.update_attributes!(update_params)

    head(204)
  end

  def destroy
    current_issue = Issue.find(params[:issue_id])

    issue_observation = MessageConfiguration::IssueObservation.find_by(id: params[:id])

    issue_observation.destroy! if issue_observation.present? && issue_observation.persisted?

    render(partial: 'front/channels/supplementary/message_configurations_body', locals: { current_issue: current_issue })
  end

  private

  def update_params
    params.require(:message_configuration_issue_observation).permit(MessageObservationConfigurable.all_payoff_column_names_permitted)
  end
end