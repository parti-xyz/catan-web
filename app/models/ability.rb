class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :partial], :all
    can [:slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_users, :slug_references, :slug_comments, :slug_polls,
      :slug_talks, :slug_wikis, :search], Issue
    if user
      can :manage, Section do |section|
        section.issue.made_by? user
      end
      can [:update, :remove_logo, :remove_cover], Issue do |issue|
        user.maker?(issue)
      end
      can [:create, :new_intro, :search_by_tags], [Issue]

      can [:update, :destroy], [Talk], user_id: user.id
      can :create, [Talk] do |specific|
        specific.issue.try(:postable?, user)
      end

      can :manage, [Comment, Vote, Upvote, Member], user_id: user.id
      can :manage, Related do |related|
        user.maker?(related.issue)
      end
      can :update, Wiki
      if user.admin?
        can :manage, [Issue, Related, Blind]
      end
    end
  end
end
