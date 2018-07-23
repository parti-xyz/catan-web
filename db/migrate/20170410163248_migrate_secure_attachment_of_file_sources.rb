class MigrateSecureAttachmentOfFileSources < ActiveRecord::Migration[4.2]
  def change
    rename_column :file_sources, :attachment, :deprecated_attachment
    rename_column :file_sources, :secure_attachment, :attachment

    change_column_null :file_sources, :attachment, false
    change_column_null :file_sources, :deprecated_attachment, true
  end
end
