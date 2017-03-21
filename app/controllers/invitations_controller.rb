class InvitationsController < ApplicationController
  load_and_authorize_resource
  def destroy
    @invitation.destroy
  end
end
