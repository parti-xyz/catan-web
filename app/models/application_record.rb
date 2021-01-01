class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def smart_exists_association?(association_name)
    if association(association_name).loaded?
      send(association_name).any?
    else
      send(association_name).exists?
    end
  end

  def striped_tags(text)
    striped_text = text&.strip
    return '' if striped_text.blank?

    sanitize_html(striped_text)
  end

  def sanitize_html(text)
    HTMLEntities.new.decode ::Catan::SpaceSanitizer.new.do(text)
  end
end
