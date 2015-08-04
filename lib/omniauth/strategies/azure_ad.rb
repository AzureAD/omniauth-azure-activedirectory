require 'adal'
require 'jwt'
require 'omniauth'
require 'omniauth/azure_ad/jwt'
require 'open-uri'

module OmniAuth
  module Strategies
    # A strategy for authentication against Azure Active Directory.
    class AzureAD
      include OmniAuth::AzureAD
      include OmniAuth::Strategy

      uid { @claims[JWTClaim::SUBJECT] }

      info { @claims }

      extra { { session_state: @session_state } }

      AUTH_CTX = ADAL::AuthenticationContext.new
      DEFAULT_RESPONSE_TYPE = 'code id_token'

      # This is called by OmniAuth.
      def request_phase
        redirect authorize_endpoint
      end

      ##
      # This is called by OmniAuth after the user enters credentials at the
      # authorization endpoint. OmniAuth exposes a Rack::Request object in the
      # global scope called `request`. The `request.params` field is a hash that
      # contains the content of the posted form.
      def callback_phase
        error = request.params['error_reason'] || request.params['error']
        @claims = {}
        parse_authorization_response unless error
        super
      end

      def parse_authorization_response
        @session_state = request.params['session_state']
        @claims, @header = JWT.decode(request.params['id_token'], nil, false)
        @auth_code = request.params['code']
      end

      # @return String
      def authorize_endpoint
        uri_string = AUTH_CTX.authorization_request_url(
          options[:resource],
          options[:client_id],
          options[:redirect_uri] || callback_url,
          nonce: options[:nonce] || SecureRandom.uuid,
          response_type: options[:response_type] || DEFAULT_RESPONSE_TYPE).to_s
      end

      private

      # @return String
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end

OmniAuth.config.add_camelization 'azuread', 'AzureAD'
