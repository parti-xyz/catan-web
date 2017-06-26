class Message < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper

    { comment: Comment::Entity,
      upvote: Upvote::Entity,
      invitation: Invitation::Entity,
      parti: Issue::Entity,
      member: Member::Entity,
      member_request: MemberRequest::Entity,
      option: Option::Entity,
      survey: Survey::Entity
    }.each do |key, entity|
      type = ( key == :parti ? 'Issue' : key.to_s.classify)
      expose :"#{key}_messagable", using: entity, if: lambda { |instance, options| instance.messagable_type == type } do |instance|
        instance.messagable
      end
    end

    expose :id, :messagable_type
    expose :user, using: User::Entity
    expose :sender, using: User::Entity
    expose :post, using: Post::Entity
    expose :issue, using: Issue::Entity, as: :parti
    expose :header do |instance|
      if instance.issue.blank? and instance.group.blank?
        "@#{instance.sender.nickname}"
      else
        if instance.issue.blank?
          instance.group.title
        else
          "#{instance.issue.title} < #{instance.issue.group.title}"
        end
      end
    end
    expose :title do |instance|
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
    expose :body do |instance|
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
    expose :fcm do |instance|
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
      (JSON.parse(json)['data'] || {}).select {|k,_| %w(type param url).include?(k) }
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
