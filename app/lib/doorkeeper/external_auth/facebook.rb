module Doorkeeper
  module ExternalAuth
    class Facebook
      def initialize(auth_code)
        @auth_code = auth_code
      end

      def uid
        facebook_data["id"]
      end

      def email
        facebook_data["email"]
      end

      def image_url
        guard do
          @image_url ||= facebook_api.get_picture_data("me", {type: 'large'}).dig('data', 'url')
        end
      end

      def provider
        :facebook
      end

      private

      def facebook_api
        guard do
          @facebook_api ||= Koala::Facebook::API.new(@auth_code)
        end
      end

      def facebook_data
        guard do
          @facebook_data ||= facebook_api.get_object("me", {fields: "email"})
        end
      end

      def guard
        return unless block_given?
        begin
          yield
        rescue Koala::KoalaError => e
          ::Rails.logger.info e
          raise Doorkeeper::Errors::DoorkeeperError.new(:fail_external_auth)
        end
      end
    end
  end
end
