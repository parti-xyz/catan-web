class ApplicationController < ActionController::Base
  include PartiUrlHelper
  include GroupHelper
  include StoreLocation

  protect_from_forgery with: :exception
  before_action :prepare_meta_tags, if: "request.get?"
  before_action :set_device_type
  before_action :blocked_private_group
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
    result
  end

  def after_sign_out_path_for(resource_or_scope)
    result = super
    return root_url(subdomain: params['group_slug']) if params['group_slug'].present?
    result
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
      (controller_name == 'passwords') or
      (controller_name == 'members' and action_name == 'magic_join') or
      (controller_name == 'members' and action_name == 'magic_form')
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
      site:        options[:site_name],
      title:       options[:title],
      reverse:     true,
      image:       view_context.asset_url(options[:image]),
      description: options[:description],
      keywords:    options[:keywords],
      canonical:   current_url,
      twitter: {
        site_name: options[:site_name],
        site: '@parti_xyz',
        card: options[:twitter_card_type],
        description: twitter_description(options),
        image: view_context.asset_url(options[:image])
      },
      og: {
        url: current_url,
        site_name: options[:site_name],
        title: options[:og_title] || "#{options[:title]} | #{options[:site_name]}",
        image: view_context.asset_url(options[:image]),
        description: og_description,
        type: 'website'
      }
    }
  end

  def default_meta_options
    {
      site_name: current_group.blank? ? "빠띠" : "#{current_group.title} 그룹빠띠",
      title: current_group.try(:site_title) || "민주적 일상 커뮤니티 '빠띠'",
      description: current_group.try(:site_description) || "더 나은 민주주의의 기반요소를 통합한 기민하고, 섬세하고, 일상적인 커뮤니티 플랫폼, 빠띠!",
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
    flash[:notice] = model.errors.full_messages.join('<br>').html_safe
  end

  def set_device_type
    request.variant = :mobile if (browser.device.mobile?)
  end

  def having_link_or_file_posts_page(issue = nil)
    base = issue.nil? ? Post.all.displayable_in_current_group(current_group) : Post.of_issue(issue)
    base = base.having_link_of_file
    @is_last_page = base.empty?

    how_to = (issue.present? or params[:sort] == 'recent') ? :previous_of_recent : :previous_of_hottest

    previous_last = Post.with_deleted.find_by(id: params[:last_id])
    @posts = base.send(how_to, previous_last).limit(20)
    current_last = @posts.last
    @is_last_page = (@is_last_page or base.send(how_to, current_last).empty?)
  end

  def having_poll_and_survey_posts_page(issue = nil)
    base = Post.having_poll.or(Post.having_survey)
    base = issue.nil? ? base.displayable_in_current_group(current_group) : base.of_issue(issue)
    @is_last_page = base.empty?

    how_to = (issue.present? or params[:sort] == 'recent') ? :previous_of_recent : :previous_of_hottest
    previous_last = Post.with_deleted.find_by(id: params[:last_id])

    @posts = base.send(how_to, previous_last).limit(20)

    current_last = @posts.last
    @is_last_page = (@is_last_page or base.send(how_to, current_last).empty?)
  end

  #bugfix redactor2-rails
  def redactor_current_user
    redactor2_current_user
  end

  private

  def prepare_store_location
    store_location(current_group)
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
end
