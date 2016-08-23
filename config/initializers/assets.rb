# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w(email.css application_xs.css application_default.css vendors.css mobile.js)
Rails.application.config.assets.precompile << Proc.new do |path|
  groups_path = 'groups'
  if path =~ /\.(css)\z/
    full_path = Rails.application.assets.resolve(path)
    app_assets_path = Rails.root.join('app', 'assets', 'stylesheets', groups_path).to_path
    if full_path.starts_with?(app_assets_path) and !path.starts_with?("#{groups_path}/_")
      true
    else
      false
    end
  else
    false
  end
end
