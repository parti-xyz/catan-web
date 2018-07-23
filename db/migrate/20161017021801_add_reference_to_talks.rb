class AddReferenceToTalks < ActiveRecord::Migration[4.2]
  def change
    add_reference :talks, :reference, polymorphic: true, index: true
    add_index :talks, [:id, :reference_id, :reference_type], unique: true
  end
end
