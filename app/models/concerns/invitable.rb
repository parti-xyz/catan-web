module Invitable
  extend ActiveSupport::Concern

  included do
    has_many :invitations, as: :joinable, dependent: :destroy
  end

  def invited?(recipient)
    case recipient
    when User
      invitations.exists?(recipient: recipient)
    else
      invitations.exists?(recipient_email: recipient)
    end
  end
end
