module Choosable
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :choice, in: [:agree, :disagree], predicates: true, scope: true
    scope :agreed, -> { by_choice('agree') }
    scope :disagreed, -> { by_choice('disagree') }
    scope :by_choice, ->(choice) { where(choice: choice) }
  end
end
