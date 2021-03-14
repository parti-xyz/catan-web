class AddTokenInvitations < ActiveRecord::Migration[5.2]
  class Invitation < ApplicationRecord
    def friendly_token(length = 20)
      # To calculate real characters, we must perform this operation.
      # See SecureRandom.urlsafe_base64
      rlength = (length * 3) / 4
      self.token = SecureRandom.urlsafe_base64(rlength).tr('lIO0', 'sxyz')
    end
  end

  def change
    add_column :invitations, :token, :string

    reversible do |dir|
      dir.up do
        Invitation.all.each do |invitation|
          invitation.friendly_token
          invitation.save
        end

        change_column_null :invitations, :token, false
      end
    end
  end
end
