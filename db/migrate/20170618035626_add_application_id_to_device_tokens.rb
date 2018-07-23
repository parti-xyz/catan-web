class AddApplicationIdToDeviceTokens < ActiveRecord::Migration[4.2]
  def up
    add_column :device_tokens, :application_id, :string

    query = <<-SQL.squish
      UPDATE device_tokens SET application_id = 'xyz.parti.catan'
    SQL
    ActiveRecord::Base.connection.execute query

    change_column_null :device_tokens, :application_id, false
  end
  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
