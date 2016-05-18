class Group < ActiveRecord::Base
  include Watchable

  belongs_to :user
  has_many :issues

  def watched_by? someone
    watches.exists? user: someone
  end

  def best_articles
    Post.best_articles_in_issues(issues, 4).map(&:specific)
  end

  def best_opinions
    Post.best_opinions_in_issues(issues, 4).map(&:specific)
  end

  def best_talks
    Post.best_talks_in_issues(issues, 4).map(&:specific)
  end
end
