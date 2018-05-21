class IssuesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover]
  before_action :fetch_issue_by_slug, only: [:new_posts_count, :slug_home, :slug_hashtag, :slug_members, :slug_links_or_files, :slug_polls_or_surveys, :slug_folders, :slug_wikis]
  load_and_authorize_resource
  before_action :verify_issue_group, only: [:slug_home, :slug_hashtag, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :slug_folders, :edit]
  before_action :prepare_issue_meta_tags, only: [:show, :slug_home, :slug_hashtag, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :slug_members, :slug_folders]
  before_action :noindex_meta_tag, except: [:indies]

  def home
    if current_group.blank?
      if request.subdomain.present?
        redirect_to root_url(subdomain: nil)
      else
        index
      end
    else
      group_issues(current_group)
      @posts_pinned = current_group.pinned_posts(current_user)

      @polls_and_surveys = Post.where.any_of(Post.having_poll, Post.having_survey, Post.where.not(decision: nil))
      @polls_and_surveys = @polls_and_surveys.not_private_blocked_of_group(current_group, current_user)
      @polls_and_surveys = @polls_and_surveys.order_by_stroked_at.limit(7)
      @recent_posts = Post.not_in_dashboard_of_group(current_group, current_user).order_by_stroked_at.limit(4)

      if %w(youthmango).include? current_group.slug
        render 'group_home_parties_first'
      else
        unless view_context.is_infinite_scrollable?
          @posts = watched_posts(params[:page])
        end

        render 'group_home_union'
      end
    end
  end

  def index
    if current_group.blank?
      if params[:keyword].present?
        params[:sort] ||= 'hottest'
        @issues = search_and_sort_issues(Issue.searchable_issues(current_user), params[:keyword], params[:sort], 3)
      elsif params[:subject].present?
        @issues = LandingPage.section_for_issue_subject.find_by(title: params[:subject]).try(:parsed_section_for_issue_subject)
      else
        @groups = Group.not_private_blocked(current_user).sort_by_name
        @groups = @groups.to_a.reject { |group| group.issues.count <= 0 }
      end

      render 'index'
    else
      group_issues(current_group, params[:category_slug])
      render 'group_index'
    end
  end

  def indies
    params[:sort] ||= 'hottest'
    @issues = search_and_sort_issues(Group.indie.issues.not_private_blocked(current_user), params[:keyword], params[:sort], 3)
  end

  def search_by_tags
    @issues = Issue.alive.only_public_in_current_group(current_group)
    if params[:selected_tags] == [""]
      @issues = @issues.hottest
      @no_tags_selected = 'yes'
    else
      conditions = []
      conditions << Issue.tagged_with(params[:selected_tags], :any => true)

      LandingPage.section_for_issue_subject.where(title: params[:selected_tags]).each do |landing_page|
        conditions << landing_page.parsed_section_for_issue_subject
      end

      @issues = @issues.where.any_of(*conditions)
    end
    @issues = @issues.to_a.reject { |i| i.private_blocked?(current_user) }
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to smart_issue_home_url(@issue)
  end

  def slug_home
    render 'slug_home_blocked' and return if private_blocked?(@issue)

    if params[:q].present?
      if params[:q].try(:strip).starts_with?('#')
        hashtag = params[:q].strip[1..-1].try(:strip).presence
        redirect_to smart_issue_hashtag_url(@issue, hashtag) and return if hashtag.present?
      end
      @search_q = PostSearchableIndex.sanitize_search_key params[:q]
    end
    @posts_pinned = @issue.posts.pinned.order('pinned_at desc')

    prepare_posts_page
  end

  def slug_hashtag
    render 'slug_home_blocked' and return if private_blocked?(@issue)

    @hashtag = params[:hashtag].strip.gsub(/( )/, '_').downcase
    prepare_posts_page
  end

  def slug_polls_or_surveys
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:sort] == 'hottest' ? :hottest : :order_by_stroked_at
    @posts = Post.where.any_of(Post.having_poll, Post.having_survey, Post.where.not(decision: nil))
    @posts = @posts.of_issue(@issue).send(how_to).page(params[:page]).per(3*5)
  end

  def slug_wikis
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:status] == 'inactive' ? :inactive : :active
    @posts = Post.having_wiki(how_to.to_s).of_issue(@issue).order_by_stroked_at.order_by_stroked_at.page(params[:page]).per(3*5)
  end

  def slug_folders
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:sort] == 'hottest' ? :hottest : :order_by_stroked_at
    @folders = @issue.folders.sort_by_name
    @current_folder = Folder.find_by(id: params[:folder_id])
    @posts = Post.none
    @posts = Post.where(folder: @current_folder).send(how_to).page(params[:page]).per(3*5) if @current_folder.present?
  end

  def slug_members
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)

    base = @issue.members.recent
    base = smart_search_for(base, params[:keyword], profile: (:admin if user_signed_in? and current_user.admin?)) if params[:keyword].present?
    @members = base.page(params[:page]).per(3 * 10)
  end

  def slug_links_or_files
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    how_to = params[:sort] == 'hottest' ? :hottest : :order_by_stroked_at
    @posts = Post.having_link_or_file.of_issue(@issue).send(how_to).page(params[:page]).per(3*5)
  end

  def new
  end

  def edit
  end

  def create
    if @issue.private? and current_group.try(:met_private_issues_quota?)
      flash[:notice] = t('labels.group.met_private_issues_quota')
      render 'new' and return
    end

    @issue.group_slug ||= Group.default_slug(current_group)
    if @issue.group.private_blocked?(current_user)
      redirect_to smart_group_url(@issue.group) and return
    end

    @issue.strok_by(current_user)

    if @issue.save
      MemberIssueService.new(issue: @issue, user: current_user, is_organizer: true, need_to_message_organizer: false, is_force: true).call
      if @issue.is_default?
        IssueForceDefaultJob.perform_async(@issue.id, current_user.id)
      end
      IssueCreateNotificationJob.perform_async(@issue.id, current_user.id)
      redirect_to smart_issue_home_url(@issue)
    else
      render 'new'
    end
  end

  def update
    @issue.assign_attributes(issue_params)
    if @issue.private_changed? and @issue.private? and current_group.try(:met_private_issues_quota?)
      flash[:notice] = t('labels.group.met_private_issues_quota')
      render 'new' and return
    end
    if @issue.group_slug_changed? and !current_user.admin?
      flash[:notice] = t('unauthorized.default')
      render 'edit' and return
    end
    @origin_issue = Issue.find(@issue.id)
    target_group = Group.find_by(slug: @issue.group_slug)
    if @issue.group_slug_changed? and !@issue.movable_to_group?(target_group)
      @target_group = target_group
      @out_of_member_users = @target_group.out_of_member_users(@issue.member_users)

      if target_group.private? or target_group.private_blocked?(current_user)
        render 'warning_out_of_members_notice' and return
      else
        GroupMemberJob.perform_async(target_group.id, @out_of_member_users.map(&:id))
      end
    end

    new_organizer_members = []
    ActiveRecord::Base.transaction do
      if params[:issue].has_key?(:organizer_nicknames)
        organizer_users = User.parse_nicknames(@issue.organizer_nicknames)
        organizer_users.each do |user|
          member = @issue.members.find_by(user: user)
          next if member.blank?

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
        @issue.blinds.destroy_all
        (@issue.blinds_nickname.split(",") || []).map(&:strip).compact.uniq.each do |nickname|
          user = User.find_by(nickname: nickname)
          if user.present?
            @issue.blinds.build(user: user)
          end
        end
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
        redirect_to smart_issue_home_url(@issue)
      else
        errors_to_flash @issue
        render 'edit'
      end
    end
  end

  def destroy
    IssueDestroyJob.perform_async(current_user.id, @issue.id, params[:message])
    flash[:success] = t('views.started_issue_destroying')
    redirect_to root_path
  end

  def remove_logo
    @issue.remove_logo!
    @issue.save
    redirect_to [:edit, @issue]
  end

  def remove_cover
    @issue.remove_cover!
    @issue.save
    redirect_to [:edit, @issue]
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

  def my_menus
    @group = Group.find_by(slug: params[:group_slug])
    render_404 and return if @group.blank?

    @issues = current_user.member_issues.alive.sort_by_name
    @issues = @issues.of_group(@group)
  end

  def add_my_menu
    unless current_user.my_menu?(@issue)
      current_user.my_menus.create(issue: @issue)
    end
    if request.format.js?
      render 'issues/add_or_remove_my_menu'
    else
      redirect_to(request.referrer || smart_issue_home_path_or_url(@issue))
    end
  end

  def remove_my_menu
    current_user.my_menus.where(issue: @issue).destroy_all
    if request.format.js?
      render 'issues/add_or_remove_my_menu'
    else
      redirect_to(request.referrer || smart_issue_home_path_or_url(@issue))
    end
  end

  protected

  def mobile_navbar_title_slug_home
    @issue.title
  end

  def mobile_navbar_title_slug_hashtag
    "##{@hashtag}" if @hashtag.present?
  end

  private

  def prepare_posts_page
    issue_posts = @issue.posts.order(last_stroked_at: :desc)
    issue_posts = issue_posts.search(@search_q) if @search_q.present?
    issue_posts = issue_posts.tagged_with(@hashtag) if @hashtag.present?

    if view_context.is_infinite_scrollable?
      if request.format.js?
        @previous_last_post = Post.with_deleted.find_by(id: params[:last_id])

        limit_count = ( @previous_last_post.blank? ? 10 : 20 )
        @posts = issue_posts.limit(limit_count).previous_of_post(@previous_last_post)

        current_last_post = @posts.last
        @is_last_page = (issue_posts.empty? or issue_posts.previous_of_post(current_last_post).empty?)
      end
    else
      @list_url = smart_issue_home_path_or_url(@issue)
      @posts = issue_posts.page(params[:page])
      @recommend_posts = Post.of_undiscovered_issues(current_user).where.not(issue_id: @issue.id).after(1.month.ago).hottest.order_by_stroked_at
    end
  end

  def group_issues(group, category_slug = nil)
    @issues = Issue.displayable_in_current_group(group)
    @issues = @issues.hottest
    @issues = @issues.categorized_with(category_slug) if category_slug.present?
    @issues = @issues.to_a.reject { |issue| private_blocked?(issue) }
  end

  def search_and_sort_issues(issue, keyword, sort, item_a_row = 4)
    tags = (keyword.try(:split) || []).map(&:strip).reject(&:blank?)
    result = issue
    result = result.where.any_of(Issue.alive.search_for(keyword), Issue.alive.tagged_with(tags, any: true)) if keyword.present?

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

    result = result.categorized_with(params[:category]) if params[:category].present?
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
      :organizer_nicknames, :blinds_nickname, :telegram_link, :tag_list, :category_slug,
      :private, :notice_only, :is_default, :group_slug)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} | 팀과 커뮤니티를 위한 민주주의 플랫폼, 빠띠"),
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
end
