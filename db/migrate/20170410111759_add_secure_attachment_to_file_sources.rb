class AddSecureAttachmentToFileSources < ActiveRecord::Migration[4.2]
  def change
    add_column :file_sources, :secure_attachment, :string
  end
end
