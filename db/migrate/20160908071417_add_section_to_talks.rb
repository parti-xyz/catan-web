class AddSectionToTalks < ActiveRecord::Migration[4.2]
  def up
    add_reference :talks, :section, index: true
  end
end
