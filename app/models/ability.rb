class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :survey_social_card, :partial, :modal, :magic_form], :all
    can [:home, :indies, :slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_members, :slug_links_or_files,
      :slug_posts, :slug_wikis, :search, :slug_polls_or_surveys, :new, :slug_hashtag], Issue
    can [:more_comments, :wiki], Post
    can [:users], [Upvote]
    if user
      can [:update, :destroy, :destroy_form, :remove_logo, :remove_cover, :new_admit_members, :admit_members], Issue do |issue|
        user.is_organizer?(issue)
      end
      can [:create, :new_intro, :search_by_tags, :bookmarks, :add_bookmark, :remove_bookmark], [Issue]

      can [:pinned], [Post]
      can [:update, :destroy, :edit_decision, :update_decision, :decision_histories], [Post], user_id: user.id
      can [:create], [Post] do |post|
        post.issue.present? and !post.issue.try(:private_blocked?, user) && post.issue.try(:postable?, user)
      end
      can [:new_wiki, :update_wiki, :edit_decision, :update_decision, :decision_histories], [Post] do |post|
        post.issue.present? and !post.issue.blind_user?(user) and !post.issue.try(:private_blocked?, user) && post.issue.try(:postable?, user)
      end
      can [:update, :activate, :inactivate, :purge, :histories], Wiki do |wiki|
        !wiki.try(:post).issue.blind_user?(user) and !wiki.try(:post).issue.try(:private_blocked?, user) && wiki.try(:post).issue.try(:postable?, user)
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
      can :reopen, Option do |option|
        option.user == user and option.canceled?
      end
      can :cancel, Option do |option|
        option.user == user and option.feedbacks_count != 0 and option.survey.open? and !option.canceled?
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
