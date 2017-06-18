class AddApplicationIdToDeviceTokens < ActiveRecord::Migration
  def change
    add_column :device_tokens, :application_id, :string

    query = <<-SQL.squish
      UPDATE device_tokens SET application_id = 'xyz.parti.catan'
    SQL
    ActiveRecord::Base.connection.execute query

    change_column_null :device_tokens, :application_id, false
  end
end
