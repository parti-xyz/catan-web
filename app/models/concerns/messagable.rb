module Messagable
  extend ActiveSupport::Concern

  included do
    has_many :messages, as: :messagable, dependent: :destroy
  end
end
