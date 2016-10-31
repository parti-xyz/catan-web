class AddPollIdToTalks < ActiveRecord::Migration
  def change
    add_reference :talks, :poll, index: true
  end
end
