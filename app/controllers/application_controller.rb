class ApplicationController < ActionController::Base
  include PartiUrlHelper
  include GroupHelper
  include MobileAppHelper
  include StoreLocation

  protect_from_forgery with: :exception
  before_action :cache_member_for_current_user
  before_action :prepare_meta_tags, if: -> { request.get? and !Rails.env.test? }
  before_action :set_device_type
  before_action :blocked_iced_group
  before_action :block_not_exists_group
  before_action :blocked_private_group
  before_action :logging_mobile_app

  after_action :prepare_unobtrusive_flash_frontable
  after_action :prepare_store_location
  after_action :visit_group
  after_action :flash_to_headers

  around_action :set_current_user
  around_action :set_current_group

  layout -> { get_layout }

  if Rails.env.production? or Rails.env.staging?
    rescue_from ActiveRecord::RecordNotFound, ActionController::UnknownFormat do |exception|
      render_404 unless self.performed?
    end
    rescue_from ActionController::InvalidCrossOriginRequest, ActionController::InvalidAuthenticityToken do |exception|
      unless self.performed?
        self.response_body = nil
        if request.format.html?
          redirect_to root_url, :alert => I18n.t('errors.messages.invalid_auth_token')
        else
          render_403
        end
      end
    end
  end
  unless Rails.env.test?
    rescue_from CanCan::AccessDenied do |exception|
      unless self.performed?
        if request.format.html?
          redirect_to root_url, :alert => exception.message
        else
          render_403
        end
      end
    end
  end

  def render_404
    return if self.performed?
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404.html", layout: false, status: 404 }
      format.js { head 404 }
      format.json { head 404 }
    end
  end

  def render_403
    return if self.performed?
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/403.html", layout: false, status: 403 }
      format.js { head 403 }
      format.json { head 403 }
    end
  end

  def render_500
    return if self.performed?
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/500.html", layout: false, status: 403 }
      format.js { head 500 }
      format.json { head 500 }
    end
  end

  def prepare_meta_tags(options={})
    set_meta_tags build_meta_options(options)
  end

  def after_sign_in_path_for(resource)
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}
    group = Group.find_by_slug(omniauth_params['group_slug'])
    group ||= current_group

    result = (stored_location(group) || '/').to_s

    if group.present?
      group_root = root_url(subdomain: group.subdomain)
      if helpers.implict_front_namespace?
        result = group_root
      else
        result = URI.join(group_root, (stored_location(group) || '/').to_s).to_s
      end
    end

    if is_mobile_app_get_request?(request)
      mobile_app_setup_sessions_path(after_sign_in_path: result)
    else
      result
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    result = super
    result = root_url(subdomain: params['group_slug']) if params['group_slug'].present?

    after_sign_out_path(after_sign_out_path: result)
  end

  helper_method :current_group
  helper_method :host_group
  helper_method :mobile_navbar_title

  def respond_to_html_only(&block)
    respond_to do |format|
      format.html {
        block.call
      }
      format.any { render_404 }
    end
  end

  private

  def blocked_iced_group
    return if request.subdomain.blank?
    return if current_group.blank?
    return unless current_group.iced?
    return if (controller_name == 'pages' && action_name == 'iced') ||
      (controller_name == 'groups') ||
      (controller_name == 'members' && action_name == 'cancel')

    if request.xhr?
      return if request.get?
      render_403 && return
    end

    logger.debug("controller_name, action_name: #{controller_name}, #{action_name}")
    redirect_to front_iced_path
  end

  def block_not_exists_group
    if current_group.blank? and request.subdomain.present?
      redirect_to root_url(subdomain: nil)
    end
  end

  def blocked_private_group
    return if current_group.blank? || current_user&.admin?

    if current_group.private_blocked?(current_user) &&
    !(
      (controller_name == 'pages' && action_name == 'iced') ||
      (controller_name == 'issues' && action_name == 'home') ||
      (controller_name == 'issues' && action_name == 'index' && request.subdomain.blank?) ||
      (controller_name == 'member_requests' && action_name == 'create') ||
      (controller_name == 'sessions') ||
      (controller_name == 'users' && action_name == 'pre_sign_up') ||
      (controller_name == 'users' && action_name == 'email_sign_in') ||
      (controller_name == 'passwords') ||
      (controller_name == 'members' && action_name == 'magic_join') ||
      (controller_name == 'members' && action_name == 'magic_form') ||
      (controller_name == 'members' && action_name == 'join_group_form') ||
      (controller_name == 'my_menus') ||
      (is_a?(Group::Eduhope::MembersController) && action_name == 'admit') ||
      (helpers.implict_front_namespace? || helpers.explict_front_namespace?) && (
        (controller_name == 'member_requests' && action_name == 'intro') ||
        (controller_name == 'member_requests' && action_name == 'new') ||
        (controller_name == 'member_requests' && action_name == 'create') ||
        (controller_name == 'users') ||
        (controller_name == 'registrations') ||
        (controller_name == 'confirmations')
      )
    )
      logger.debug("controller_name, action_name: #{controller_name}, #{action_name}")
      if helpers.implict_front_namespace? || helpers.explict_front_namespace?
        redirect_to intro_front_member_requests_path
      else
        respond_to do |format|
          format.html do
            prepare_store_location
            render 'home/group_home_private_blocked'
          end
          format.js do
            render 'home/group_home_private_blocked.js'
          end
        end
      end
    end
  end

  def build_meta_options(options)
    unless options.nil?
      options.compact!
      options.reverse_merge! default_meta_options
    else
      options = default_meta_options
    end

    current_url = request.url
    og_description = (view_context.strip_tags options[:description]).truncate(160)
    {
      title:       options[:title],
      reverse:     true,
      image:       view_context.asset_url(options[:image]),
      description: options[:description],
      keywords:    options[:keywords],
      canonical:   current_url,
      twitter: {
        site: '@parti_coop',
        card: options[:twitter_card_type],
        description: twitter_description(options),
        image: view_context.asset_url(options[:image])
      },
      og: {
        url: current_url,
        title: options[:og_title] || options[:title],
        image: view_context.asset_url(options[:image]),
        description: og_description,
        type: 'website'
      }
    }.reject{ |_,v| v.nil? }
  end

  def default_meta_options
    {
      title: current_group.try(:title) || "팀과 커뮤니티를 위한 민주주의 플랫폼, #{I18n.t('labels.app_name_human')}",
      description: current_group.try(:site_description) || "#{I18n.t('labels.app_name_human')}로 더 민주적인 일상을 만들어요",
      keywords: current_group.try(:site_keywords) || "빠띠 카누, 정치, 민주주의, 조직, 투표, 모임, 의사결정, 일상 민주주의, 토의, 토론, 논쟁, 논의, 회의",
      image: view_context.asset_url(current_group.try(:seo_image) || "parti_seo.png"),
      twitter_card_type: "summary_card"
    }
  end

  def twitter_description(options)
    limit = 140
    title = view_context.strip_tags options[:title]
    description = view_context.strip_tags options[:description]
    if title.length > limit
      title.truncate(limit)
    else
      description.truncate(limit)
    end
  end

  def meta_issue_title(issue)
    issue.title
  end

  MOBILE_NAVBAR_TITLE = {
    "users#posts" => :dynamic,
    "users#pre_sign_up" => "가입",
    "users#email_sign_in" => "로그인",
    "users/sessions#new" => "가입",
    "users/registrations#edit" => "설정",
    "dashboard#index" => "내 홈",
    "dashboard#intro" => "시작",
    "bookmark#index" => "북마크",
    "pages#landing" => "시작",
    "pages#privacy" => "방침",
    "pages#terms" => "약관",
    "issues#home" => nil,
    "issues#destroy_form" => "채널 삭제",
    "issues#new_admit_members" => "초대",
    "issues#index" => I18n.t('labels.app_name_human'),
    "issues#new" => "채널 만들기",
    "issues#edit" => "설정",
    "issues#slug_home" => :dynamic,
    "issues#slug_links_or_files" => "자료",
    "issues#slug_wikis" => "위키",
    "issues#slug_polls_or_surveys" => "토론",
    "issues#slug_members" => "멤버",
    "issues#slug_hashtag" => :dynamic,
    "issues#slug_folders" => "폴더",
    "members#index" => "멤버",
    "posts#beholders" => "확인 멤버",
    "posts#unbeholders" => "미확인 멤버",
    "posts#decision_histories" => "토론 이력",
    "wikis#histories" => "위키 이력",
    "posts#new_wiki" => "위키 게시",
    "posts#pinned" => "고정 게시글",
    "posts#edit" => "게시글 수정",
    "posts#show" => "게시글 상세",
    "wiki_histories#show" => "위키 이력",
    "links_or_files#index" => "자료",
    "polls_or_surveys#index" => "토론",
    "wikis#index" => "위키",
    "relateds#new" => "관련 채널",
    "messages#index" => "알림",
    "group/configurations#new" => "그룹 만들기",
    "group/configurations#edit" => "설정",
    "group/members#new_admit" => "멤버 추가",
    "group/members#edit_magic_link" => "초대 링크",
    "group/members#magic_form" => "초대",
    "group/members#index" => "멤버",
    "group/managements#index" => "관리",
    "hashtags#show" => :dynamic
  }
  def mobile_navbar_title
    key = "#{controller_name}##{action_name}"
    result = ApplicationController::MOBILE_NAVBAR_TITLE[key]
    if :dynamic == result
      if self.methods.include?(:"mobile_navbar_title_#{action_name}")
        result = send(:"mobile_navbar_title_#{action_name}")
      else
        result = nil
      end
    end
    result
  end

  def errors_to_flash(model)
    return if model.errors.empty?
    result ||= ""
    result += model.errors.full_messages.join('<br>')

    if helpers.explict_front_namespace?
      flash[:alert] = result.html_safe
    else
      flash[:error] = result.html_safe
    end
  end

  def set_device_type
    request.variant = :mobile if (browser.device.mobile?)
  end

  def prepare_store_location
    if controller_name == 'pages' && action_name == 'landing'
      store_location_force(root_url(subdomain: nil))
    elsif !user_signed_in? && (
      (controller_name == 'pages' && action_name == 'privacy') ||
      (controller_name == 'pages' && action_name == 'terms')
    )
      store_location_force(root_url(subdomain: nil))
    else
      store_location(current_group)
    end
  end

  def get_layout
    if current_group.present? or @issue.present? or @group.present?
      'group'
    else
      'application'
    end
  end

  def current_group
    @__current_group ||= fetch_group request
  end

  def host_group
    current_group || Group.open_square
  end

  def verify_group(issue)
    return true if issue.blank?
    return true if (issue.group_subdomain || "") == request.subdomain

    if request.format.html?
      redirect_to subdomain: issue.group_subdomain
    else
      render_403
    end

    false
  end

  def smart_search_for(model, q, options = {})
    return model.search_for(q, options) if q.blank?

    model.search_for smart_search_keyword(q), options
  end

  def smart_search_keyword(q)
    return if q.blank?

    q.split.map { |t| "\"#{t}\"" }.join(" OR ")
  end

  def logging_mobile_app
    if is_mobile_app_get_request? request
      Rails.logger.info "SPARK APP - catan-agent : #{current_mobile_app_agent(request)} #{current_mobile_app_version(request)}"
    else
      Rails.logger.info "SPARK APP - NO "
    end
  end

  def current_ability
    Ability.new(current_user, current_group)
  end

  def authorize_parent!(parent)
    return if parent.blank?
    authorize! "#{params[:controller]}##{params[:action]}".to_sym, parent
  end

  def cache_member_for_current_user
    current_user.try(:cache_member)
  end

  def visit_group
    return unless request.get?
    return if request.xhr?
    return if !user_signed_in? or current_user.last_visitable_id_previously_changed?

    if current_group.present? and response.status < 400 and response.status >= 200
      current_user.update_attributes(last_visitable: current_group)
    end
  end

  def set_current_user
    Current.user = current_user
    yield
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.user = nil
  end

  def set_current_group
    Current.group = current_group
    yield
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.group = nil
  end

  def flash_to_headers
    return unless request.xhr?
    return if response.headers["X-Trubolinks-Redirect"] == 'true'
    #avoiding XSS injections via flash
    flash_json = Hash[flash.map{ |k,v| [k, ERB::Util.h(v)] }].to_json
    response.headers['X-Flash-Messages'] = flash_json
    flash.discard
  end

  def force_remote_replace_header
    response.headers['X-Force-Remote-Replace-Header'] = 'true'
  end

  def turbolinks_redirect_to(url = {}, options = {})
    response.headers["X-Trubolinks-Redirect"] = 'true'
    redirect_to(url, options)
  end

  def turbolinks_reload
    render template: 'front/pages/reload', format: :js
  end

  def prepare_unobtrusive_flash_frontable
    return if helpers.explict_front_namespace? || helpers.implict_front_namespace?
    prepare_unobtrusive_flash
  end

  def announce_post_interaction_not_member_users_message(outcome)
    return if outcome.result.blank?

    not_member_users = outcome.result[:not_member_users]
    if not_member_users.present? && not_member_users.any?
      "필독 요청한 #{not_member_users.map(&:nickname).join(', ')}님은 그룹 멤버가 아니라 필독 요청할 수 없습니다."
    end
  end

  def group_accessible_only_posts(group)
    return Post.none if group.blank?
    Post.where(issue: group_accessible_only_issues(group))
      .never_blinded(current_user)
  end

  def current_group_accessible_only_posts
    group_accessible_only_posts(current_group)
  end

  def group_accessible_only_issues(group)
    return Issue.none if group.blank?
    group.issues.accessible_only(current_user)
  end

  def group_announcement_posts(group)
    group_accessible_only_posts(group)
      .includes(announcement: [:current_user_audience])
      .where.not(announcement_id: nil)
      .where("announcements.stopped_at": nil)
  end

  def current_group_announcement_posts
    group_announcement_posts(current_group)
  end

  def current_need_to_notice_announcement_posts
    add_condition_need_to_notice_announcement_posts(current_group_announcement_posts)
  end

  def need_to_notice_announcement_posts(group)
    add_condition_need_to_notice_announcement_posts(group_announcement_posts(group))
  end

  def add_condition_need_to_notice_announcement_posts(post_relations)
    post_relations
      .where('audiences.noticed_at IS NULL')
      .where('announcements.stopped_at IS NULL')
  end

  def response_header_modal_command(command)
    response.headers["X-Modal-Command"] = command
  end
end
