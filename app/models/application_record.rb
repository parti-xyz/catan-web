class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def smart_exists_association?(association_name)
    if association(association_name).loaded?
      send(association_name).any?
    else
      send(association_name).exists?
    end
  end
end
