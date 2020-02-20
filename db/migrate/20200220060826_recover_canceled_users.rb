class RecoverCanceledUsers < ActiveRecord::Migration[5.2]
  def change
    transaction do
      execute "UPDATE users SET uid = '_____CANCEL_____#{SecureRandom.hex(10)}' WHERE uid is null"
    end
  end
end
