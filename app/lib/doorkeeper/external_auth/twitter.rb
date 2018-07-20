module Doorkeeper
  module ExternalAuth
    class Twitter
      attr_accessor :secret

      def initialize(auth_code)
        @auth_code = auth_code
      end

      def uid
        twitter_api[:id_str]
      end

      def email
        twitter_api[:email]
      end

      def image_url
        guard do
          @image_url ||= @init_twitter_client.user.profile_image_uri(:original)
        end
      end

      def provider
        :twitter
      end

      private

      def twitter_api
        guard do
          @init_twitter_client ||= ::Twitter::REST::Client.new do |config|
            config.consumer_key = ENV['TWITTER_APP_ID']
            config.consumer_secret = ENV['TWITTER_APP_SECRET']
            config.access_token = @auth_code
            config.access_token_secret = @secret
          end

          @twitter_api = ::Twitter::REST::Request.new(@init_twitter_client, :get,
            'https://api.twitter.com/1.1/account/verify_credentials.json', include_email: true).perform
        end
      end

      def guard
        return unless block_given?
        begin
          yield
        rescue => e
          ::Rails.logger.info e
          raise Doorkeeper::Errors::DoorkeeperError.new(:fail_external_auth)
        end
      end
    end
  end
end
