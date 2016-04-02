class ApplicationController < ActionController::Base
  include PartiUrlHelper

  protect_from_forgery with: :exception
  before_action :prepare_meta_tags, if: "request.get?"
  after_filter :prepare_unobtrusive_flash
  after_filter :store_location

  def store_location
    return unless request.get?
    if (!request.fullpath.match("/users") && !request.xhr?)
      store_location_for(:user, request.fullpath)
    end
  end

  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound do |exception|
      render_404
    end
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to root_url, :alert => exception.message
    end
    rescue_from ActionController::InvalidAuthenticityToken do |exception|
      redirect_to root_url, :alert => I18n.t('errors.messages.invalid_auth_token')
    end
  end

  def render_404
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  end

  def prepare_meta_tags(options={})
    set_meta_tags build_meta_options(options)
  end

  def after_sign_in_path_for(resource)
    path = super
    return dashboard_path if path == slug_issue_path(slug: :all)
    path
  end

  def redactor_authenticate_user!
    authenticate_user!
  end

  def redactor_current_user
    current_user
  end

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
        title: "#{options[:title]} | #{options[:site_name]}",
        image: view_context.asset_url(options[:image]),
        description: og_description,
        type: 'website'
      }
    }
  end

  def default_meta_options
    {
      site_name: "빠띠",
      title: "유쾌한 민주주의 플랫폼",
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
end
