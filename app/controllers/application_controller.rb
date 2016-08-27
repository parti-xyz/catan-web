class ApplicationController < ActionController::Base
  include PartiUrlHelper

  protect_from_forgery with: :exception
  before_action :prepare_meta_tags, if: "request.get?"
  before_action :set_device_type
  after_filter :prepare_unobtrusive_flash
  after_filter :store_location

  layout -> { get_layout }

  def store_location
    return unless request.get?
    if (!request.fullpath.match("/users") && !request.xhr?)
      store_location_for(:user, request.fullpath)
    end
  end

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
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  end

  def prepare_meta_tags(options={})
    set_meta_tags build_meta_options(options)
  end

  def after_sign_in_path_for(resource)
    result = super
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}
    return URI.join(root_url(subdomain: omniauth_params['group_slug']), result).to_s if omniauth_params['group_slug'].present?
    result
  end

  def after_sign_out_path_for(resource_or_scope)
    result = super
    return root_url(subdomain: params['group_slug']) if params['group_slug'].present?
    result
  end

  helper_method :current_group

  private

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
      site_name: (current_group.blank? ? "빠띠" : "#{current_group.name} 빠띠"),
      title: current_group.try(:site_title) || "함께 만드는 온라인 광장",
      description: "더 나은 민주주의의 기반요소를 통합한 기민하고, 섬세하고, 일상적인 민주주의 플랫폼, 빠띠!",
      keywords: "정치, 민주주의, 조직, 투표, 모임, 의사결정, 일상 민주주의, 토의, 토론, 논쟁, 논의, 회의",
      image: view_context.asset_url("parti_seo.png"),
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

  def meta_issue_full_title(issue)
    "#{meta_issue_title(issue)} | #{default_meta_options[:site_name]}"
  end

  def errors_to_flash(model)
    flash[:notice] = model.errors.full_messages.join('<br>').html_safe
  end

  def set_device_type
    request.variant = :mobile if (browser.device.mobile?)
  end

  def articles_page(issue = nil)
    articles_base = issue.nil? ? Article.all.only_group_or_all_if_blank(current_group) : Article.of_issue(issue)

    if issue.nil?
      case params[:sort]
      when 'recent'
        articles_base = articles_base.recent
      else
        articles_base = articles_base.hottest
      end
    else
      articles_base = articles_base.recent
    end

    previous_last_article = Article.find_by(id: params[:last_id])
    @articles = articles_base.previous_of_article(previous_last_article).limit(20)
    current_last_article = @articles.last

    @is_last_page = (articles_base.empty? or articles_base.previous_of_article(current_last_article).empty?)
  end

  def opinions_page(issue = nil)
    opinions_base = issue.nil? ? Opinion.all.only_group_or_all_if_blank(current_group) : Opinion.of_issue(issue)

    if issue.nil?
      case params[:sort]
      when 'recent'
        opinions_base = opinions_base.recent
      else
        opinions_base = opinions_base.hottest
      end
    else
      articles_base = opinions_base.recent
    end

    previous_last_opinion = Opinion.find_by(id: params[:last_id])
    @opinions = opinions_base.previous_of_opinion(previous_last_opinion).limit(20)
    current_last_opinion = @opinions.last

    @is_last_page = (opinions_base.empty? or opinions_base.previous_of_opinion(current_last_opinion).empty?)
  end

  def talks_page(issue = nil)
    talks_base = issue.nil? ? Talk.all.only_group_or_all_if_blank(current_group) : Talk.of_issue(issue)

    if issue.nil?
      case params[:sort]
      when 'recent'
        talks_base = talks_base.recent
      else
        talks_base = talks_base.hottest
      end
    else
      talks_base = talks_base.recent
    end

    @talks = talks_base.page(params[:page])
  end

  def notes_page(issue = nil)
    notes_base = issue.nil? ? Note.all.only_group_or_all_if_blank(current_group) : Note.of_issue(issue)

    if issue.nil?
      case params[:sort]
      when 'recent'
        notes_base = notes_base.recent
      else
        notes_base = notes_base.hottest
      end
    else
      notes_base = notes_base.recent
    end

    previous_last_note = Note.find_by(id: params[:last_id])
    @notes = notes_base.previous_of_note(previous_last_note).limit(20)
    current_last_note = @notes.last

    @is_last_page = (notes_base.empty? or notes_base.previous_of_note(current_last_note).empty?)
  end

  #bugfix redactor2-rails
  def redactor_current_user
    redactor2_current_user
  end

  private

  def get_layout
    if current_group.present?
      'group'
    else
      'application'
    end
  end

  def current_group
    Group.find_by_slug request.subdomain
  end

  def verify_group(issue)
    return if issue.blank?
    return if !request.format.html?

    redirect_to subdomain: nil and return if !issue.on_group? and current_group.present?
    redirect_to subdomain: issue.group.slug and return if issue.on_group? and current_group.blank?
  end
end
