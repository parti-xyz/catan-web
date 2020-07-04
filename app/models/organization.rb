class Organization
  include ActiveModel::Model

  attr_accessor :slug, :title, :email, :disable_summary_emails, :root_url

  DIC = [
    Organization.new(slug: 'default', title: I18n.t('labels.app_name_human'), email: 'help@parti.coop', disable_summary_emails: false, root_url: (Rails.env.production? ? "https://parti.xyz" : "https://#{ENV["HOST"]}")),
    Organization.new(slug: 'butterknifecrew', title: '버터나이프크루', email: 'community@butterknifecrew.kr', disable_summary_emails: true, root_url: (Rails.env.production? ? "https://butterknifecrew.parti.xyz" : "https://butterknifecrew.#{ENV["HOST"]}"))
  ]

  def self.find_by_slug(slug)
    DIC.find { |organization| organization.slug == slug }
  end

  def self.default
    find_by_slug('default')
  end

  def default?
    slug == 'default'
  end
end