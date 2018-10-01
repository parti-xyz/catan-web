class AddEnableTraceDeviceTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :enable_trace_device_token, :boolean, default: false
  end
end
