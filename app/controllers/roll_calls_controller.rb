class RollCallsController < ApplicationController
  load_and_authorize_resource :event
  load_and_authorize_resource :roll_call, through: :event, shallow: true


  def attend
    @roll_call = @event.roll_calls.find_or_initialize_by(user: current_user) do |roll_call|
      roll_call.status = :attend
    end
    @roll_call.update(status: :attend)
  end

  def absent
    @roll_call = @event.roll_calls.find_or_initialize_by(user: current_user) do |roll_call|
      roll_call.status = :absent
    end
    @roll_call.update(status: :absent)
  end

  def to_be_decided
    @roll_call = @event.roll_calls.find_or_initialize_by(user: current_user) do |roll_call|
      roll_call.status = :to_be_decided
    end
    @roll_call.update(status: :to_be_decided)
  end

  def invite_form
  end

  def invite
    @invitee = User.find_by(nickname: params[:user_nickname])
    return if @invitee.blank?

    if @event.invitable_softly_for?(@invitee) or params[:force]
      @roll_call = @event.roll_calls.find_or_create_by(user: @invitee) do |roll_call|
        roll_call.status = :invite
      end
    end
  end

  def destroy
    @roll_call.destroy
  end
end
