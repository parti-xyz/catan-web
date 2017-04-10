class AddSecureAttachmentToFileSources < ActiveRecord::Migration
  def change
    add_column :file_sources, :secure_attachment, :string
  end
end
