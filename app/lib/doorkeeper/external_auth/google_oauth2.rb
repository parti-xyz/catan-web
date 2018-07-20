require 'google/apis/oauth2_v2'

module Doorkeeper
  module ExternalAuth
    class GoogleOauth2
      def initialize(token)
        @token = token
      end

      def uid
        user_data['sub']
      end

      def email
        user_data['email']
      end

      def image_url
        user_data['picture']
      end

      def provider
        :google_oauth2
      end

      private

      def user_data
        return @google_api if @google_api.present?

        begin
          ::Rails.logger.debug "token : #{@token}"
          response = RestClient.get("https://www.googleapis.com/oauth2/v3/tokeninfo", {params: {id_token: @token}})
          @google_api = JSON.parse(response.body)
          return @google_api
        rescue Exception => e
          ::Rails.logger.info e
          raise Doorkeeper::Errors::DoorkeeperError.new(:fail_external_auth)
        end
      end
    end
  end
end
