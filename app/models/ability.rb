class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :social_card], :all
    can [:slug, :users, :exist, :slug_articles, :slug_comments, :slug_opinions, :slug_talks], Issue
    if user
      can :manage, [Issue, Related] if user.admin?
      can :create, [Article, Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch]
      can :manage, [Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch], user_id: user.id
    end
    if user.admin?
      can :manage, Article
    end
  end
end
