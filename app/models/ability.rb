class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :poll_social_card, :survey_social_card, :partial, :modal, :magic_form], :all
    can [:home, :indies, :slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_members, :slug_links_or_files,
      :slug_posts, :slug_wikis, :search, :slug_polls_or_surveys, :new, :slug_hashtag,
      :slug_folders], Issue
    can [:more_comments, :wiki], Post
    can [:users], [Upvote]
    if user
      can [:update, :destroy, :destroy_form, :remove_logo, :remove_cover, :new_admit_members, :admit_members], Issue do |issue|
        user.is_organizer?(issue)
      end
      can [:create, :new_intro, :search_by_tags, :my_menus, :add_my_menu, :remove_my_menu], [Issue]

      can [:create, :destroy, :update], [Folder] do |folder|
        folder.issue.present? and folder.issue.try(:postable?, user)
      end

      can [:pinned], [Post]
      can [:update, :destroy, :move_to_issue, :move_to_issue_form], [Post], user_id: user.id
      can [:create], [Post] do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [:edit_folder, :update_folder], [Post] do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [:new_wiki, :update_wiki], [Post] do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [:update, :activate, :inactivate, :purge, :histories], Wiki do |wiki|
        wiki.try(:post).issue.try(:postable?, user)
      end
      can [:pin, :unpin, :readers, :unreaders], Post do |post|
        user.is_organizer?(post.issue)
      end

      can [:edit_decision, :update_decision, :decision_histories], [Post] do |post|
        if post.decisionable?
          (post.user_id == user.id) or
          (post.issue.present? and !post.issue.blind_user?(user) and !post.issue.try(:private_blocked?, user))
        else
          false
        end
      end
      can [:read], DecisionHistory do |decision_history|
        post = decision_history.post
        post.present? and post.issue.present? and post.issue.try(:postable?, user)
      end

      can [:manage], [Bookmark] do |bookmark|
        !bookmark.persisted? or bookmark.user == user
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
