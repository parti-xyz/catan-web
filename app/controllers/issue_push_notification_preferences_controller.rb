class IssuePushNotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def new
    @issues_no_preference = current_user.member_issues.where.not(id: current_user.issue_push_notification_preferences.select(:issue_id))
  end

  def create
    issue_ids = (params[:issue_push_notification_preference][:issue_id] || '').split(',').map(&:to_i)
    ActiveRecord::Base.transaction do
      issue_ids.each do |issue_id|
        issue_push_notification_preference = current_user.issue_push_notification_preferences.find_or_initialize_by(issue_id: issue_id)
        issue_push_notification_preference.assign_attributes(issue_push_notification_preference_params)
        unless issue_push_notification_preference.save
          errors_to_flash(issue_push_notification_preference)
          return
        end
      end
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: edit_user_registration_path) }
      format.js
    end
  end

  def edit
    @issue_push_notification_preference = current_user.issue_push_notification_preferences.find(params[:id])
  end

  def update
    @issue_push_notification_preference = current_user.issue_push_notification_preferences.find(params[:id])
    unless @issue_push_notification_preference.update_attributes(value: params[:issue_push_notification_preference][:value])
      errors_to_flash(@issue_push_notification_preference)
    end
  end

  def destroy
    unless current_user.issue_push_notification_preferences.destroy(params[:id])
      errors_to_flash(@issue_push_notification_preference)
    end
  end

  private

  def issue_push_notification_preference_params
    params.require(:issue_push_notification_preference).permit(:value)
  end
end
