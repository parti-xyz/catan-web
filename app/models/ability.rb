class Ability
  include CanCan::Ability

  def initialize(user, current_group)
    can [:read, :read_all, :behold, :unbehold, :poll_social_card, :survey_social_card, :partial, :modal, :magic_form, :header], :all
    can [:home, :slug, :users, :exist, :new_posts_count, :slug_home,
      :slug_members, :slug_links_or_files,
      :slug_posts, :slug_wikis, :search, :slug_polls_or_surveys, :new, :slug_hashtag,
      :slug_folders], Issue
    can [:more_comments, :wiki], Post
    can [:users], Upvote
    can [:reload], Event

    if user
      can [:update, :destroy, :destroy_form, :remove_logo, :remove_cover, :new_admit_members, :admit_members], Issue do |issue|
        user.is_organizer?(issue) || user.is_organizer?(issue.group)
      end
      can [:create, :new_intro, :search_by_tags, :selections], [Issue]
      can [:update_category, :destroy_category], Issue do |issue|
        user.is_organizer?(issue.group)
      end
      can [:pin, :freeze, :wake], Issue do |issue|
        user.is_organizer?(issue) || user.is_organizer?(issue.group)
      end
      can [:announce], Issue do |issue|
        user.is_organizer?(issue.group)
      end
      can [:create, :new, :new_post_form], Folder
      can [:destroy, :update, :detach_post, :attach_post, :move_form, :move], [Folder] do |folder|
        folder.issue.present? and folder.issue.try(:postable?, user)
      end
      can [:manage_folders], [Issue] do |issue|
        issue.try(:postable?, user)
      end
      can [:main_wiki], Issue do |issue|
        user.is_organizer?(issue) || user.is_organizer?(issue.group)
      end

      can [:pinned, :new], [Post]
      can [:update, :destroy, :move_to_issue, :move_to_issue_form], [Post] do |post|
        post.user_id == user.id || user.is_organizer?(post.issue) || user.is_organizer?(post.issue.group)
      end
      can [:create], [Post]

      can [:edit_folder, :update_folder, :update_title], [Post] do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [:front_update_title, :front_update_label], [Post] do |post|
        post.group.member?(user)
      end
      can [:new_wiki, :update_wiki, :wiki], [Post] do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [:update, :activate, :inactivate, :purge, :histories], Wiki do |wiki|
        wiki.try(:post).issue.try(:postable?, user)
      end
      can [:pin, :unpin], Post do |post|
        user.is_organizer?(post.issue) || user.is_organizer?(post.issue.group)
      end
      can [ :beholders, :unbeholders], Post do |post|
        post.issue.present? and post.issue.try(:postable?, user)
      end
      can [ :unread_until], Post do |post|
        post.issue.present? and post.issue.postable?(user)
      end

      can_nested [:attend, :absent, :to_be_decided], Event, RollCall do |event|
        event.takable_self_roll_call?(user)
      end
      can_nested [:invite_form, :invite], Event, RollCall do |event|
        event.invitable_by?(user)
      end
      can :destroy, RollCall do |roll_call|
        (roll_call.user != user) and roll_call.event.invitable_by?(user)
      end
      can_nested [:accept, :reject, :hold], Event, RollCall

      can [:edit], Event do |event|
        return false if event.post.issue.blind_user?(user)
        event.post.user == user or event.taken_roll_call?(user)
      end
      can [:update], Event do |event|
        return false if event.post.issue.blind_user?(user)
        event.post.user == user or event.attend?(user)
      end

      can [:show_decision, :update_decision, :decision_histories], [Post] do |post|
        if post.decisionable?(user)
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

      can [:bookmark], Post do |post|
        post.group.member?(user)
      end

      can [:bookmark], Comment do |comment|
        comment.post&.group&.member?(user)
      end

      can :manage, [Comment, Upvote, Member], user_id: user.id
      can :update, Comment do |comment|
        comment.is_decision? && comment&.post&.issue&.group&.member?(user)
      end

      can [:destroy], Member do |member|
        member.user == user or user.is_organizer?(member.joinable)
      end
      can [:invite_group_issues], User do |invited_user|
        current_group.present? and current_group.try(:member?, user)
      end
      can [:create], MemberRequest, user_id: user.id
      can [:accept, :reject, :reject_form], MemberRequest do |request|
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

      if current_group.present? and current_group.organized_by?(user)
        can [:admit, :magic_link], Group
        can [:manage], Category
        can [:manage], GroupHomeComponent
      end

      can [:main_wiki, :labels], Group do |group|
        group.organized_by?(user)
      end

      can [:stop, :restart], Announcement do |announcement|
        announcement.post.user == user || announcement.post.issue.group.organized_by?(user)
      end

      can [:update], [MessageConfiguration::GroupObservation, MessageConfiguration::IssueObservation, MessageConfiguration::PostObservation] do |observation|
        observation.user == user
      end

      can [:update], MessageConfiguration::RootObservation do |observation|
        observation.group.organized_by?(user)
      end

      if user.admin?
        can :manage, [Folder, Issue, Related, Blind, Role, Group, MemberRequest, Member, Invitation, Category, Announcement]
        cannot :update, Post do |post|
          user != post.user
        end
      end
    end
  end

  private

  def can_nested(actions, parent_klass, child_klass, &block)
    actions = [actions].flatten
    can actions.map { |action| "#{child_klass.to_s.underscore.pluralize}##{action.to_s}".to_sym }, parent_klass, &block
    can actions, child_klass
  end
end
