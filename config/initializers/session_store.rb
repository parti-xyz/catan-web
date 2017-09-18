# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: "_catan_1_11_session#{ Rails.env.production? ? "" : "_#{Rails.env}" }", domain: :all, tld_length: 2
