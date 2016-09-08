class AddSectionToTalks < ActiveRecord::Migration
  def up
    add_reference :talks, :section, index: true
  end
end
