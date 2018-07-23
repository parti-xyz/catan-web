class AddPollIdToTalks < ActiveRecord::Migration[4.2]
  def change
    add_reference :talks, :poll, index: true
  end
end
