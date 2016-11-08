module Doorkeeper
  module ExternalAuth
    class Twitter
      attr_accessor :secret

      def initialize(auth_code)
        @auth_code = auth_code
      end

      def uid
        twitter_api.user.id
      end

      def email
        twitter_api.user.email
      end

      def image_url
        guard do
          @image_url ||= twitter_api.user.profile_image_uri(:original)
        end
      end

      def provider
        :twitter
      end

      private

      def twitter_api
        guard do
          @twitter_api ||= ::Twitter::REST::Client.new do |config|
            config.consumer_key = ENV['TWITTER_APP_ID']
            config.consumer_secret = ENV['TWITTER_APP_SECRET']
            config.access_token = @auth_code
            config.access_token_secret = @secret
          end
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
