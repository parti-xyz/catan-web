class AddReferenceToTalks < ActiveRecord::Migration
  def change
    add_reference :talks, :reference, polymorphic: true, index: true
    add_index :talks, [:id, :reference_id, :reference_type], unique: true
  end
end
