Koala::Facebook::OAuth.class_eval do
  def initialize_with_default_settings(*args)
    raise "application id and/or secret are not specified in the envrionment" unless ENV['FACEBOOK_APP_ID'] && ENV['FACEBOOK_APP_SECRET']
    initialize_without_default_settings(ENV['FACEBOOK_APP_ID'].to_s, ENV['FACEBOOK_APP_SECRET'].to_s, args.first)
  end

  alias_method_chain :initialize, :default_settings
end
