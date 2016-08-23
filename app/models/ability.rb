class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :social_card, :partial], :all
    can [:slug_show], Campaign
    can [:slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_users, :slug_articles, :slug_comments, :slug_opinions,
      :slug_talks, :slug_wikis, :slug_notes, :search], Issue
    if user
      can [:update, :remove_logo, :remove_cover], Issue do |issue|
        user.maker?(issue)
      end
      can :create, [Issue, Article, Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch, Note]
      can :manage, [Article, Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch, Note], user_id: user.id
      can :manage, Related do |related|
        user.maker?(related.issue)
      end
      can :update, Wiki
      if user.admin?
        can :manage, [Campaign, Issue, Related, FeaturedIssue, FeaturedCampaign]
        can :recrawl, Article
      end
    end
  end
end
