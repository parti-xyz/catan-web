class AddCanceledAtToOptions < ActiveRecord::Migration
  def change
    add_column :options, :canceled_at, :datetime
  end
end
