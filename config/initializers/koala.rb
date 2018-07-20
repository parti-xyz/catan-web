module KoalaWithDefaultSetting
  def initialize(*args)
    raise "application id and/or secret are not specified in the envrionment" unless ENV['FACEBOOK_APP_ID'] && ENV['FACEBOOK_APP_SECRET']
    super(ENV['FACEBOOK_APP_ID'].to_s, ENV['FACEBOOK_APP_SECRET'].to_s, args.first)
  end
end
Koala::Facebook::OAuth.send(:prepend, KoalaWithDefaultSetting)
