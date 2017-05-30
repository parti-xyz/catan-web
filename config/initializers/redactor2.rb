Rails.application.config.to_prepare do
  Redactor2Rails.image_model.class_eval do
    validates :data, file_size: { less_than_or_equal_to: 10.megabytes, greater_than: 0.byte }
  end
end
