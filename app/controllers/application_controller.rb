class ApplicationController < ActionController::Base
  include PartiUrlHelper
  include GroupHelper
  include MobileAppHelper
  include StoreLocation

  protect_from_forgery with: :exception
  before_action :prepare_meta_tags, if: "request.get?"
  before_action :set_device_type
  before_action :blocked_private_group
  before_action :logging_mobile_app

  after_action :prepare_unobtrusive_flash
  after_action :prepare_store_location

  layout -> { get_layout }

  if Rails.env.production? or Rails.env.staging?
    rescue_from ActiveRecord::RecordNotFound, ActionController::UnknownFormat do |exception|
      render_404
    end
    rescue_from CanCan::AccessDenied do |exception|
      self.response_body = nil
      redirect_to root_url, :alert => exception.message
    end
    rescue_from ActionController::InvalidCrossOriginRequest, ActionController::InvalidAuthenticityToken do |exception|
      self.response_body = nil
      redirect_to root_url, :alert => I18n.t('errors.messages.invalid_auth_token')
    end
  end

  def render_404
    self.response_body = nil
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404.html", layout: false, status: 404 }
      format.all { head 404 }
    end
  end

  def prepare_meta_tags(options={})
    set_meta_tags build_meta_options(options)
  end

  def after_sign_in_path_for(resource)
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}
    group = Group.find_by_slug(omniauth_params['group_slug'])
    group ||= current_group

    result = stored_location(group) || '/'
    result = URI.join(root_url(subdomain: group.subdomain), result).to_s if group.present?

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

  private

  def blocked_private_group
    return if current_group.blank? or current_user.try(:admin?)

    if current_group.private_blocked? current_user and
    !(
      (controller_name == 'issues' and action_name == 'home') or
      (controller_name == 'issues' and action_name == 'index') or
      (controller_name == 'member_requests' and action_name == 'create') or
      (controller_name == 'sessions') or
      (controller_name == 'users' and action_name == 'pre_sign_up') or
      (controller_name == 'users' and action_name == 'email_sign_in') or
      (controller_name == 'users' and action_name == 'valid_email') or
      (controller_name == 'users' and action_name == 'invalid_email') or
      (controller_name == 'passwords') or
      (controller_name == 'members' and action_name == 'magic_join') or
      (controller_name == 'members' and action_name == 'magic_form') or
      (self.is_a? Group::Eduhope::MembersController and action_name == 'admit')
    )

      redirect_to root_url
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
        site: '@parti_xyz',
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
    }
  end

  def default_meta_options
    {
      title: current_group.try(:site_title) || "팀과 커뮤니티를 위한 민주주의 플랫폼, 빠띠",
      description: current_group.try(:site_description) || "빠띠로 더 민주적인 일상을 만들어요",
      keywords: current_group.try(:site_keywords) || "정치, 민주주의, 조직, 투표, 모임, 의사결정, 일상 민주주의, 토의, 토론, 논쟁, 논의, 회의",
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

  def errors_to_flash(model)
    flash[:notice] = model.errors.full_messages.join('<br>').html_safe if model.errors.any?
  end

  def set_device_type
    request.variant = :mobile if (browser.device.mobile?)
  end

  def prepare_store_location
    #랜딩 페이지를 볼 떄는 랜딩 페이지를 저장하게 하자.
    #비로그인 회원이 랜딩페이지를 볼때는 랜딩페이지가 / 인데
    #로그인 후에는 /discover 로 바꿔야 하는. discover_root_path
    if !user_signed_in? and request.fullpath == "/" and current_group.nil?
      store_location_force(discover_url(subdomain: nil))
    else
      store_location(current_group)
    end
  end

  def get_layout
    if current_group.present?
      'group'
    else
      'application'
    end
  end

  def current_group
    @__current_group ||= fetch_group request
  end

  def host_group
    current_group || Group.indie
  end

  def verify_group(issue)
    return if issue.blank?
    return if !request.format.html?

    redirect_to subdomain: issue.group.subdomain and return unless issue.displayable_group?(current_group)
  end

  def smart_search_for(model, q, options = {})
    return model.search_for(q, options) if q.blank?

    model.search_for q.split.map { |t| "\"#{t}\"" }.join(" OR "), options
  end

  def logging_mobile_app
    if is_mobile_app_get_request? request
      Rails.logger.info "SPARK APP - catan-agent : #{current_mobile_app_agent(request)} #{current_mobile_app_version(request)}"
    else
      Rails.logger.info "SPARK APP - NO "
    end
  end
end
