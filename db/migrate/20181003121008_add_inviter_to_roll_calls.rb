class AddInviterToRollCalls < ActiveRecord::Migration[5.2]
  def change
    add_reference :roll_calls, :inviter, null: true, index: true
  end
end
