class EventsController < ApplicationController
  load_and_authorize_resource

  def reload
  end

  def edit
  end

  def update
    @event.assign_attributes(event_params)
    @event.setup_schedule
    @event.setup_location

    if @event.need_to_rsvp?
      @event.roll_calls
        .with_status(:attend)
        .where.not(user: current_user)
        .update_all(status: :to_be_decided, updated_at: DateTime.now)
    end
    @event.save
  end

  private

  def event_params
    params.require(:event).permit(:title, :body, :enable_self_attendance,
      :start_at_date, :start_at_time, :end_at_date, :end_at_time,
      :unfixed_schedule, :unfixed_location, :all_day_long,
      :location)
  end
end
