class User::Mailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that you mailer uses the devise views

  def confirmation_instructions(record, token, opts={})
    @newbie = record.confirmed_at.blank?
    init_owner(record, opts)
    opts[:subject] = "[#{@organization.title}] 계정 확인"
    super
  end

  def password_change(record, opts={})
    init_owner(record, opts)
    opts[:subject] = "[#{@organization.title}] 계정 비밀번호 변경됨"
    super
  end

  def reset_password_instructions(record, token, opts={})
    init_owner(record, opts)
    opts[:subject] = "[#{@organization.title}] 비밀번호 재설정"
    super
  end

  private

  def init_owner record, opts
    if record.touch_group_slug.present?
      group = Group.find_by(slug: record.touch_group_slug)
      @organization = group&.organization
    end
    @organization ||= Organization.default

    opts[:from] = "#{@organization.title} <#{@organization.email}>"
    opts[:reply_to] = @organization.email
  end
end