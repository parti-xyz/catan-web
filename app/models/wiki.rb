class Wiki < ActiveRecord::Base
  belongs_to :issue
  has_many :wiki_histories

  def last_history
    wiki_histories.newest
  end
end
