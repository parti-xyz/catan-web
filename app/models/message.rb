class Message < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper
    include ApiEntityHelper

    expose :post, if: lambda { |instance, options| %w(Post Comment Upvote Option Survey).include? instance.messagable_type } do |instance, options|
      sticky_comment = if instance.messagable.respond_to? :sticky_comment_for_message
        instance.messagable.sticky_comment_for_message
      else
        nil
      end
      post_for_message = instance.messagable.try(:post_for_message)
      Post::Entity.represent post_for_message, options.merge(sticky_comment: sticky_comment) if post_for_message.present?
    end
    expose :url do |instance|
      parsed_asset_url = URI.parse(Rails.application.config.asset_host || "https://parti.xyz")
      host = parsed_asset_url.host
      is_https = (parsed_asset_url.scheme == 'https')
      json = ApplicationController.renderer.new(
        http_host: host,
        https: is_https)
      .render(
        partial: "messages/fcm/#{instance.messagable.class.model_name.singular}",
        locals: { message: instance }
      )
      (JSON.parse(json)['data'] || {})['url']
    end

    expose :id, :messagable_type
    expose :user, using: User::Entity
    expose :sender, using: User::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :header do |instance|
      if instance.issue.blank? and instance.group.blank?
        "@#{instance.sender.nickname}"
      else
        if instance.issue.blank?
          instance.group.title_short_format
        else
          "#{instance.issue.group.title_short_format} / #{instance.issue.title}"
        end
      end
    end
    expose :title do |instance|
      Rails.cache.fetch ["api-message-title", instance.id], race_condition_ttl: 30.seconds, expires_in: 12.hours do
        parsed_asset_url = URI.parse(Rails.application.config.asset_host || "https://parti.xyz")
        host = parsed_asset_url.host
        is_https = (parsed_asset_url.scheme == 'https')
        ApplicationController.renderer.new(
          http_host: host,
          https: is_https)
        .render(
          partial: "messages/api/title/#{instance.messagable.class.model_name.singular}",
          locals: { message: instance }
        )
      end
    end
    expose :body do |instance|
      Rails.cache.fetch ["api-message-body", instance.id], race_condition_ttl: 30.seconds, expires_in: 12.hours do
        parsed_asset_url = URI.parse(Rails.application.config.asset_host || "https://parti.xyz")
        host = parsed_asset_url.host
        is_https = (parsed_asset_url.scheme == 'https')
        ApplicationController.renderer.new(
          http_host: host,
          https: is_https)
        .render(
          partial: "messages/api/body/#{instance.messagable.class.model_name.singular}",
          locals: { message: instance }
        )
      end
    end
    with_options(format_with: lambda { |dt| dt.try(:iso8601) }) do
      expose :read_at, :created_at
    end
  end

  belongs_to :user
  belongs_to :sender, class_name: User
  belongs_to :messagable, -> { try(:with_deleted) || all }, polymorphic: true

  scope :recent, -> { order(id: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :only_upvote, -> { where(messagable_type: Upvote.to_s) }

  def post
    messagable.try(:post)
  end

  def issue
    messagable.issue_for_message
  end

  def group
    messagable.group_for_message
  end

  def action_params_hash
    JSON.parse(action_params)
  end
end
