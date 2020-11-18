class AddClusterOfMessages < ActiveRecord::Migration[5.2]
  def change
    add_reference :messages, :cluster_owner, polymorphic: true, index: true, null: true
  end
end
