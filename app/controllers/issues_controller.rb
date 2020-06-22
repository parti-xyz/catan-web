class IssuesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover, :destroy_form, :update_category, :destroy_category, :read_all, :unread_until, :freeze]
  before_action :fetch_issue_by_slug, only: [:new_posts_count, :slug_home, :slug_hashtag, :slug_members, :slug_links_or_files, :slug_polls_or_surveys, :slug_folders, :slug_wikis]
  load_and_authorize_resource
  before_action :verify_issue_group, only: [:slug_home, :slug_hashtag, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :slug_folders, :edit]
  before_action :prepare_issue_meta_tags, only: [:show, :slug_home, :slug_hashtag, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :slug_members, :slug_folders]
  before_action :noindex_meta_tag

  def index
    if current_group.blank?
      if params[:keyword].present?
        params[:sort] ||= 'hottest'
        @issues = search_and_sort_issues(Issue.searchable_issues.searchable_issues(current_user), params[:keyword], params[:sort], 3)
      else
        @groups = Group.not_private_blocked(current_user).hottest.sort_by_name.where(slug: Issue.alive.not_private_blocked(current_user).select(:group_slug))
        @ready_groups = Group.not_private_blocked(current_user).where('issues_count <= 0')
      end

      render 'index'
    else
      @issues = group_issues(current_group, params[:category_id], params[:dead] == 'true')
      @exists_dead_issues =  group_issues(current_group, nil, true).any?
      render 'group_index'
    end
  end

  def search_by_tags
    @issues = Issue.alive.only_public_in_current_group(current_group)
    if params[:selected_tags] == [""]
      @issues = @issues.hottest.limit(50)
      @no_tags_selected = 'yes'
    else
      base = Issue.tagged_with(params[:selected_tags], any: true).except(:select).select(:id).union(Issue.search_for(params[:selected_tags].join(' OR ')).select(:id))
      base = base.union(LandingPage.parsed_section_for_all_issue_subject(params[:selected_tags]).select(:id))

      @issues = @issues.where(id: base)
    end
    @issues = @issues.to_a.reject { |i| i.private_blocked?(current_user) }
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to smart_issue_home_url(@issue)
  end

  def header
    @issue = Issue.find params[:id]
    if request.format.html?
      redirect_to smart_issue_home_url(@issue) and return
    end
  end

  def slug_home
    render 'slug_home_blocked' and return if private_blocked?(@issue)

    if params[:nav_q].present?
      if params[:nav_q].try(:strip).starts_with?('#')
        hashtag = params[:nav_q].strip[1..-1].try(:strip).presence
        redirect_to smart_issue_hashtag_url(@issue, hashtag) and return if hashtag.present?
      end
      @search_q = PostSearchableIndex.sanitize_search_key params[:nav_q]
    end
    @posts_pinned = @issue.posts.pinned.order('pinned_at desc')
    prepare_posts_page

    if request.format.js?
      @first_post_last_stroked_at_timestamp = if params[:previous_post_last_stroked_at_timestamp].blank?
        @posts.first&.last_stroked_at&.to_i.presence || -1
      else
        params[:first_post_last_stroked_at_timestamp].to_i.presence || -1
      end
    end

    if user_signed_in?
      current_user.update_attributes(last_visitable: nil)

      if @issue.member?(current_user)
        if !@issue.marked_read_at?(current_user)
          @issue.deprecated_read!(current_user)
        end

        if (params[:nav_q].blank? and params[:previous_post_last_stroked_at_timestamp].blank? and
        @posts.present? and
        !@issue.deprecated_unread_by_last_stroked_at?(current_user, @posts.first.try(:last_stroked_at)) and
        @issue.deprecated_unread?(current_user))
          @issue.sync_last_stroked_at!
          @issue.deprecated_read!(current_user)
        end
      end
    end
  end

  def slug_hashtag
    respond_to_html_only do
      render 'slug_home_blocked'
    end and return if private_blocked?(@issue)

    @hashtag = params[:hashtag].strip.gsub(/( )/, '_').downcase
    prepare_posts_page
  end

  def slug_polls_or_surveys
    redirect_to smart_issue_home_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:sort] == 'hottest' ? :hottest : :order_by_stroked_at
    @posts = Post.having_poll.or(Post.having_survey).or(Post.where.not(decision: nil))
    @posts = @posts.of_issue(@issue).send(how_to).page(params[:page]).per(3*5)
  end

  def slug_wikis
    redirect_to smart_issue_home_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:status] == 'inactive' ? :inactive : :active
    @posts = Post.having_wiki(how_to.to_s).of_issue(@issue).order_by_stroked_at.order_by_stroked_at.page(params[:page]).per(2*6)

    if params[:folder_id].present?
      @folder = Folder.find_by(id: params[:folder_id])
      if @folder.present?
        @posts = @posts.where(folder_id: @folder.id)
      end
    end
  end

  def slug_folders
    redirect_to smart_issue_home_url(@issue) and return if private_blocked?(@issue)

    respond_to do |format|
      format.js {
        @folders = @issue.folders
        @highlight_folder = Folder.find_by(id: params[:highlight_folder_id])
      }
      format.html
    end
  end

  def slug_members
    redirect_to smart_issue_home_url(@issue) and return if private_blocked?(@issue)

    base = @issue.members.recent
    base = smart_search_for(base, params[:keyword], profile: (:admin if user_signed_in? and current_user.admin?)) if params[:keyword].present?
    @members = base.page(params[:page]).per(3 * 10)
  end

  def slug_links_or_files
    redirect_to smart_issue_home_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:sort] == 'hottest' ? :hottest : :order_by_stroked_at
    @posts = Post.having_link_or_file.of_issue(@issue).send(how_to).page(params[:page]).per(3*5)
  end

  def new
  end

  def edit
  end

  def create
    @issue.group_slug ||= Group.slug_fallback(current_group)
    if @issue.group.private_blocked?(current_user)
      redirect_to smart_group_url(@issue.group) and return
    end

    service = IssueCreateService.new(issue: @issue, current_user: current_user, current_group: current_group, flash: flash)
    if service.call
      if helpers.explict_front_namespace?
        flash[:notice] = t('activerecord.successful.messages.created')
        turbolinks_redirect_to smart_front_channel_url(@issue)
      else
        redirect_to smart_issue_home_url(@issue)
      end
    else
      errors_to_flash @issue
      if helpers.explict_front_namespace?
        render_front_edit(@issue)
      else
        render 'new'
      end
    end
  end

  def update
    @issue.assign_attributes(issue_params)
    if current_group.try(:will_violate_issues_quota?, @issue)
      flash[:notice] = t('labels.group.met_private_issues_quota')

      if helpers.explict_front_namespace?
        head 400 and return
      else
        render 'new' and return
      end
    end
    if @issue.will_save_change_to_group_slug? and !current_user.admin?
      flash[:notice] = t('unauthorized.default')

      if helpers.explict_front_namespace?
        head 400 and return
      else
        render 'edit' and return
      end
    end
    @origin_issue = Issue.find(@issue.id)
    target_group = Group.find_by(slug: @issue.group_slug)
    if @issue.will_save_change_to_group_slug? and !@issue.movable_to_group?(target_group)
      @target_group = target_group
      @out_of_member_users = @target_group.out_of_member_users(@issue.member_users)

      if target_group.private? or target_group.private_blocked?(current_user)
        render 'warning_out_of_members_notice' and return
      else
        GroupMemberJob.perform_async(target_group.id, @out_of_member_users.map(&:id))
      end
    end
    if @issue.will_save_change_to_group_slug?
      @issue.category = nil
    end

    new_organizer_members = []
    ActiveRecord::Base.transaction do
      if params[:issue].has_key?(:organizer_nicknames)
        organizer_users = User.parse_nicknames(@issue.organizer_nicknames)
        organizer_users.each do |user|
          member = @issue.members.find_by(user: user)

          if member.blank?
            member = MemberIssueService.new(issue: @issue, user: user, need_to_message_organizer: false, is_force: true).call
            next if member.blank?
          end

          unless member.is_organizer?
            member.update_attributes(is_organizer: true)
            new_organizer_members << member
          end
        end
        @issue.organizer_members.each do |member|
          member.update_attributes(is_organizer: false) unless organizer_users.include? member.user
        end
      end
      if params[:issue].has_key?(:blinds_nickname)
        deleting_nicknames = @issue.blinds.map(&:user).map(&:nickname)
        (@issue.blinds_nickname.split(",") || []).map(&:strip).compact.uniq.each do |nickname|
          user = User.find_by(nickname: nickname)
          if user.present?
            deleting_nicknames.reject!{ |nickname| nickname == user.nickname}
            @issue.blinds.build(user: user) unless @issue.blinds.exists?(user_id: user.id)
          end
        end
        @issue.blinds.where(user_id: User.where(nickname: deleting_nicknames)).destroy_all
      end
      if @issue.save
        if @issue.previous_changes["is_default"].present? and @issue.is_default?
          IssueForceDefaultJob.perform_async(@issue.id, current_user.id)
        end
        MessageService.new(@issue, sender: current_user).call
        old_organizer_members = @issue.organizer_members.to_a - new_organizer_members
        new_organizer_members.each do |member|
          next if member.user == current_user
          MessageService.new(member, sender: current_user, action: :new_organizer).call(old_organizer_members: old_organizer_members)
          MemberMailer.on_new_organizer(member.id, current_user.id).deliver_later
        end
        flash[:success] = t('activerecord.successful.messages.created')

        if helpers.explict_front_namespace?
          turbolinks_redirect_to smart_front_channel_url(@issue, folder_id: (params[:folder_id] if @issue.folders.exists?(id: params[:folder_id])))
        else
          redirect_to smart_issue_home_url(@issue)
        end
      else
        errors_to_flash(@issue)
        if helpers.explict_front_namespace?
          render_front_edit(@issue)
        else
          render 'edit'
        end
      end
    end
  end

  def destroy
    IssueDestroyJob.perform_async(current_user.id, @issue.id, params[:message])
    flash[:success] = t('views.started_issue_destroying')
    if helpers.explict_front_namespace?
      turbolinks_redirect_to root_path
    else
      redirect_to root_path
    end
  end

  def remove_logo
    @issue.remove_logo!
    @issue.save
    if helpers.explict_front_namespace?
      render_front_edit(@issue)
    else
      redirect_to [:edit, @issue]
    end
  end

  def remove_cover
    @issue.remove_cover!
    @issue.save
    if helpers.explict_front_namespace?
      render_front_edit(@issue)
    else
      redirect_to [:edit, @issue]
    end
  end

  def new_posts_count
    if params[:last_time].blank?
      @count = 0
    else
      @issue = Issue.find(params[:issue_id])
      @countable_issues = @issue.posts.next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end

    respond_to do |format|
      format.js { render 'posts/new_posts_count' }
    end
  end

  def admit_members

    @not_found_recipient_codes = []
    @ambiguous_recipient_codes = []
    @has_error_recipient_codes = false
    new_members = []
    new_invitations = []

    params[:recipients].split(/[,\s]+/).map(&:strip).reject(&:blank?).each do |recipient_code|
      recipient = nil
      if recipient_code.match /@/
        recipients = User.where(email: recipient_code)
        if recipients.count > 1
          @ambiguous_recipient_codes << recipient_code
          @has_error_recipient_codes = true
          next
        else recipients.count == 1
          recipient = recipients.first
        end
      else
        recipient = User.find_by(nickname: recipient_code)
      end

      next if @issue.invited?(recipient || recipient_code)
      next if @issue.member?(recipient)

      if recipient.present?
        new_members << MemberIssueService.new(issue: @issue, user: recipient, admit_message: params[:message], need_to_message_organizer: false, is_force: true).call
      elsif recipient_code.match /@/
        new_invitations << @issue.invitations.build(user: current_user, recipient_email: recipient_code, message: params[:message])
      else
        @not_found_recipient_codes << recipient_code
        @has_error_recipient_codes = true
      end
    end
    new_members.compact!

    unless @has_error_recipient_codes
      @success = false
      ActiveRecord::Base.transaction do
        if @issue.save and
          @issue.invitations.where(recipient: new_members.map(&:user)).destroy_all and
          @issue.invitations.where(recipient_email: new_members.map(&:user).map(&:email)).destroy_all
          @success = true
        else
          raise ActiveRecord::Rollback
        end
      end

      if @success
        new_members.each do |member|
          MemberMailer.on_admit(member.id, current_user.id).deliver_later
          MessageService.new(member, sender: current_user, action: :admit).call
        end
        new_invitations.each do |invitation|
          InvitationMailer.invite(invitation.id).deliver_later
        end
        flash[:success] = I18n.t('activerecord.successful.messages.invited')
        redirect_to new_admit_members_issue_path
      else
        errors_to_flash(current_group)
        render 'new_admit_members'
      end
    else
      flash[:error] = t('errors.messages.invitation.recipient_codes')
      render 'new_admit_members'
    end
  end

  def selections
  end

  def update_category
    @previous_category = @issue.category
    @category = Category.find_by(id: params[:category_id])
    @issue.update_attributes(category: @category)
    errors_to_flash(@issue)
  end

  def destroy_category
    @previous_category = @issue.category
    @issue.update_attributes(category: nil)
    errors_to_flash(@issue)
  end

  def read_all
    @issue = Issue.find(params[:id])
    @issue.deprecated_read!(current_user)
  end

  def unread_until
    read_at_timestamp = params[:until_post_last_stroked_at_timestamp].to_i  - 1
    return if read_at_timestamp <= 0

    @issue.deprecated_read!(current_user, Time.at(read_at_timestamp).in_time_zone)
  end

  def wake
    @issue.freezed_at = nil
    if @issue.save
      flash[:success] = '휴면을 해제했습니다.'
    else
      errors_to_flash(@issue)
    end

    if helpers.explict_front_namespace?
      turbolinks_redirect_to smart_front_channel_url(@issue, folder_id: (params[:folder_id] if @issue.folders.exists?(id: params[:folder_id])))
    else
      redirect_to smart_issue_home_url(@issue)
    end
  end

  def freeze
    @issue.freezed_at = DateTime.now
    if @issue.save
      flash[:success] = '휴면 전환했습니다.'
    else
      errors_to_flash(@issue)
    end
    if helpers.explict_front_namespace?
      turbolinks_redirect_to smart_front_channel_url(@issue, folder_id: (params[:folder_id] if @issue.folders.exists?(id: params[:folder_id])))
    else
      redirect_to smart_issue_home_url(@issue)
    end
  end

  protected

  def mobile_navbar_title_slug_home
    @issue.try(:title)
  end

  def mobile_navbar_title_slug_hashtag
    "##{@hashtag}" if @hashtag.present?
  end

  private

  def prepare_posts_page
    issue_posts = @issue.posts.order(last_stroked_at: :desc)
    issue_posts = issue_posts.search(@search_q) if @search_q.present?
    issue_posts = issue_posts.tagged_with(@hashtag) if @hashtag.present?

    if request.format.js?
      if params[:previous_post_last_stroked_at_timestamp].present?
        @previous_last_post_stroked_at_timestamp = params[:previous_post_last_stroked_at_timestamp].to_i
      end

      limit_count = ( @previous_last_post_stroked_at_timestamp.blank? ? 10 : 20 )
      @posts = issue_posts.limit(limit_count).previous_of_time(@previous_last_post_stroked_at_timestamp).to_a

      current_last_post = @posts.last
      if current_last_post.present?
        @posts += issue_posts.where(last_stroked_at: current_last_post.last_stroked_at).where.not(id: @posts).to_a
      end

      @is_last_page = (issue_posts.empty? or issue_posts.previous_of_post(current_last_post).empty?)
    end
  end

  def group_issues(group, category_id = nil, dead = false)
    issues = Issue.displayable_in_current_group(group)
    issues = if dead
      issues.dead
    else
      issues.alive
    end
    issues = issues.categorized_with(category_id) if category_id.present?
    issues = issues.to_a.reject { |issue| private_blocked?(issue) and !issue.listable_even_private? }
    issues
  end

  def search_and_sort_issues(issues, keyword, sort, item_a_row = 4)
    tags = (keyword.try(:split) || []).map(&:strip).reject(&:blank?)
    result = issues
    result = result.where(id: Issue.tagged_with(tags, any: true).except(:select).select(:id).union(Issue.search_for((smart_search_keyword(keyword))).select(:id))) if keyword.present?
    result = result.alive

    case sort
    when 'recent'
      result = result.recent
    when 'name'
      result = result.sort_by_name
    when 'recent_touched'
      result = result.recent_touched
    else
      result = result.hottest
    end

    result = result.categorized_with(params[:category_id]) if params[:category_id].present?
    result = result.page(params[:page]).per(item_a_row * 10)
    result
  end

  def fetch_issue_by_slug
    @issue = Issue.of_group(current_group).find_by slug: params[:slug]
    if @issue.blank?
      @issue_by_title = Issue.of_group(current_group).find_by(title: params[:slug].titleize)
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug,
      :organizer_nicknames, :blinds_nickname, :telegram_link, :tag_list, :category_id,
      :private, :notice_only, :is_default, :group_slug, :listable_even_private)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} | 팀과 커뮤니티를 위한 민주주의 플랫폼, #{I18n.t('labels.app_name_human')}"),
                      image: @issue.logo_url
  end

  def verify_issue_group
    verify_group(@issue)
  end

  def private_blocked?(issue)
    issue.private_blocked?(current_user) and !current_user.try(:admin?)
  end

  def watched_posts(page)
    return unless user_signed_in?
    watched_posts = current_user.watched_posts(current_group)
    watched_posts = watched_posts.order(last_stroked_at: :desc)
    watched_posts.page(page)
  end

  def noindex_meta_tag
    if current_group.present? and current_group.private?
      set_meta_tags noindex: true
      return
    end

    if @issue.present? and @issue.private?
      set_meta_tags noindex: true
      return
    end
  end

  def render_front_edit issue
    current_folder = issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?
    force_remote_replace_header
    render partial: 'front/channels/form', locals: {
      current_issue: issue,
      current_folder: current_folder
    }
  end
end
