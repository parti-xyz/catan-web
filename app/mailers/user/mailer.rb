class User::Mailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that you mailer uses the devise views

  def confirmation_instructions(record, token, opts={})
    @newbie = record.confirmed_at.blank?

    init_cloud(record, opts)

    if @cloud_plan
      opts[:subject] = "#{@group.title} 계정 확인"
    end

    super
  end

  def password_change(record, opts={})
    init_cloud(record, opts)

    if @cloud_plan
      opts[:subject] = "#{@group.title} 계정 비밀번호 변경됨"
    end
  end

  def reset_password_instructions(record, token, opts={})
    init_cloud(record, opts)

    if @cloud_plan
      opts[:subject] = "#{@group.title} 비밀번호 재설정"
    end
  end

  private

  def init_cloud record, opts
    @cloud_plan = false
    if record.confirmation_group_slug.present?
      @group = Group.find_by(slug: record.confirmation_group_slug)
      @cloud_plan = @group.present? && @group.cloud_plan?

      if @cloud_plan && @group.mailer_sender.present?
        opts[:sender] = @group.mailer_sender
        opts[:reply_to] = @group.mailer_sender
      end
    end
  end
end