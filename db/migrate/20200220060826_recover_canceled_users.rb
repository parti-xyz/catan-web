class RecoverCanceledUsers < ActiveRecord::Migration[5.2]
  def change
    transaction do
      User.all.each do |user|
        execute "UPDATE users SET uid = '_____CANCEL_____#{SecureRandom.hex(10)}' WHERE uid is null and users.id = '#{user.id}'"
      end
    end
  end
end
