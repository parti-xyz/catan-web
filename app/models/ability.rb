class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :social_card, :partial], :all
    can [:slug_show], Campaign
    can [:slug, :users, :exist, :new_comments_count, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks, :slug_wikis, :slug_notes, :search], Issue
    if user
      can :update, Issue do |issue|
        user.maker?(issue)
      end
      can :create, [Issue, Article, Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch, Note]
      can :manage, [Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch, Note], user_id: user.id
      can :update, Wiki
      if user.admin?
        can :update, Article
        can :manage, [Campaign, Issue, Related, FeaturedIssue, FeaturedCampaign]
      end
    end
  end
end
