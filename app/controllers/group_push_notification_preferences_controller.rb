class GroupPushNotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def new
    @groups_no_preference = []
    group_ids = current_user.group_push_notification_preferences.select(:group_id)
    @groups_no_preference += current_user.member_groups.where.not(id: group_ids).sort_by_name
  end

  def create
    group_ids = params[:group_push_notification_preference][:group_id]
    ActiveRecord::Base.transaction do
      group_ids.each do |group_id|
        group_push_notification_preference = current_user.group_push_notification_preferences.find_or_initialize_by(group_id: group_id)
        unless group_push_notification_preference.save
          errors_to_flash(group_push_notification_preference)
          return
        end
      end
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: edit_user_registration_path) }
      format.js
    end
  end

  def destroy
    unless current_user.group_push_notification_preferences.destroy(params[:id])
      errors_to_flash(@group_push_notification_preference).permit(group_id: [])
    end
  end

end
