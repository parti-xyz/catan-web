Rails.application.config.to_prepare do
  Redactor2Rails.image_model.class_eval do
    validates :data, file_size: { less_than: 10.megabytes }
  end
end
