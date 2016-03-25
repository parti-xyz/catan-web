class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :social_card], :all
    can [:slug, :users, :exist, :slug_posts, :slug_comments, :slug_campaign], Issue
    if user
      can :manage, [Issue, Related] if user.admin?
      can :create, [Article, Talk, Opinion, Question,
        Answer, Discussion, Proposal, Comment,
        Vote, Like, Upvote, Watch]
      can :manage, [Opinion, Talk, Question,
        Answer, Discussion, Proposal, Comment,
        Like, Upvote, Watch], user_id: user.id
      can :manage, Article do |article|
        article.user == user and article.is_talk?
      end
    end
  end
end
