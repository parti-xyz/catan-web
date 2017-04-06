class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :survey_social_card, :partial, :modal], :all
    can [:home, :slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_users, :slug_links_or_files,
      :slug_posts, :slug_wikis, :search, :slug_polls_or_surveys], Issue
    if user
      can [:update, :destroy, :remove_logo, :remove_cover], Issue do |issue|
        user.is_organizer?(issue)
      end
      can [:create, :new_intro, :search_by_tags], [Issue]

      can [:update, :destroy], [Post], user_id: user.id
      can :create, [Post] do |post|
        post.issue.try(:postable?, user)
      end
      can [:pin, :unpin, :readers, :unreaders], Post do |post|
        user.is_organizer?(post.issue)
      end

      can :manage, [Comment, Vote, Upvote, Member], user_id: user.id
      can [:destroy], Member do |member|
        member.user == user or user.is_organizer?(member.joinable)
      end
      can [:create], MemberRequest, user_id: user.id
      can [:accept, :reject], MemberRequest do |request|
        user.is_organizer?(request.issue)
      end
      can :manage, Related do |related|
        user.is_organizer?(related.issue)
      end
      can :update, Wiki
      can :destroy, Option do |option|
        option.user == user and option.feedbacks_count == 0 and option.survey.open?
      end
      can :destroy, Invitation do |invitation|
        invitation.joinable.organized_by? user
      end
      can :admit, Group do |group|
        group.organized_by?(user)
      end
      if user.admin?
        can :manage, [Issue, Related, Blind, Role, Group, MemberRequest, Member, Invitation]
      end
    end
  end
end
