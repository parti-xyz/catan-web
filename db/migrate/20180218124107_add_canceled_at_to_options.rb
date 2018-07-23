class AddCanceledAtToOptions < ActiveRecord::Migration[4.2]
  def change
    add_column :options, :canceled_at, :datetime
  end
end
