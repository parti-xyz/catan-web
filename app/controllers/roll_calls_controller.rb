class RollCallsController < ApplicationController
  load_resource :event
  load_and_authorize_resource :roll_call, through: :event, shallow: true
  before_action { authorize_parent!(@event) }

  def attend
    change_status(:attend)
  end

  def absent
    change_status(:absent)
  end

  def to_be_decided
    change_status(:to_be_decided)
  end

  def invite_form
  end

  def invite
    @invitee = User.find_by(nickname: params[:user_nickname])
    return if @invitee.blank?

    if @event.invitable_softly_for?(@invitee) or params[:force]
      @roll_call = @event.roll_calls.find_or_create_by(user: @invitee) do |roll_call|
        roll_call.status = :invite
        roll_call.inviter = current_user
      end
      if @roll_call.persisted? and
        @roll_call.status.invite? and
        @roll_call.status_previously_changed?

        # TODO
        # SendMessage.run(source: @event, sender: current_user, action: :invite, options: { roll_call: @roll_call })
      end
    end
  end

  def accept
    response_invitation(:attend)
  end

  def reject
    response_invitation(:absent)
  end

  def hold
    response_invitation(:to_be_decided)
  end

  def destroy
    return unless @roll_call.status.invite?
    if @roll_call.destroy
      @roll_call.event.messages.where(user: @roll_call.user).destroy_all
    end
  end

  private

  def change_status(status)
    @roll_call = @event.roll_calls.find_or_initialize_by(user: current_user) do |roll_call|
      roll_call.status = status
    end
    @roll_call.update(status: status)
  end

  def response_invitation(status)
    @roll_call = @event.roll_calls.find_by(user: current_user)
    return if @roll_call.blank?

    if @roll_call.update(status: status)
      if @roll_call.inviter.present?
        # TODO
        # SendMessage.run(source: @event, sender: current_user, action: params[:action].to_sym, options: { roll_call: @roll_call })
      end
    end
  end
end
