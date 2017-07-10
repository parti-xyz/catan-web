class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :survey_social_card, :partial, :modal, :magic_form], :all
    can [:home, :slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_members, :slug_links_or_files,
      :slug_posts, :slug_wikis, :search, :slug_polls_or_surveys, :new], Issue
    can [:images, :more_comments, :wiki], Post
    if user
      can [:update, :destroy, :destroy_form, :remove_logo, :remove_cover], Issue do |issue|
        user.is_organizer?(issue)
      end
      can [:create, :new_intro, :search_by_tags], [Issue]

      can [:update, :destroy], [Post], user_id: user.id
      can [:create, :new_wiki, :update_wiki], [Post] do |post|
        !post.issue.try(:private_blocked?, user) && post.issue.try(:postable?, user)
      end
      can [:update, :activate, :inactivate, :purge, :histories], Wiki do |wiki|
        !wiki.post.issue.try(:private_blocked?, user) && wiki.post.issue.try(:postable?, user)
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
      can :destroy, Option do |option|
        option.user == user and option.feedbacks_count == 0 and option.survey.open?
      end
      can :destroy, Invitation do |invitation|
        invitation.joinable.organized_by? user
      end
      can [:admit, :magic_link], Group do |group|
        group.organized_by?(user)
      end
      if user.admin?
        can :manage, [Issue, Related, Blind, Role, Group, MemberRequest, Member, Invitation]
      end
    end
  end
end
