class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :social_card, :partial], :all
    can [:slug, :users, :exist, :new_comments_count, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks], Issue
    if user
      can [:create, :update], [Issue] do |issue|
        user.maker?(issue)
      end
      can :create, [Article, Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch]
      can :manage, [Talk, Opinion, Comment,
        Vote, Like, Upvote, Watch], user_id: user.id
      if user.admin?
        can :update, Article
        can :manage, [Issue, Related]
      end
    end
  end
end
