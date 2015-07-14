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

      AUTHORIZE_ENDPOINT = 'https://login.windows.net/common/oauth2/authorize'
      OIDC_RESPONSE_TYPE = 'id_token'
      OIDC_RESPONSE_MODE = 'form_post'
      OIDC_SCOPE = 'openid'

      def request_phase
        redirect authorize_endpoint
      end

      def callback_phase
        error = request.params['error_reason'] || request.params['error']
        build_access_token unless error
        super
      end

      def build_access_token
        @session_state = request.params['session_state']
        @claims, @header = JWT.decode(request.params['id_token'], nil, false)
      end

      def authorize_endpoint
        "#{AUTHORIZE_ENDPOINT}?#{query_string}"
      end

      private

      def callback_url
        full_host + script_name + callback_path
      end

      def query_params
        { client_id: options[:client_id],
          nonce: SecureRandom.uuid,
          redirect_uri: options[:redirect_uri] || callback_url,
          response_mode: options[:response_mode] || OIDC_RESPONSE_MODE,
          response_type: options[:response_type] || OIDC_RESPONSE_TYPE,
          scope: options[:scope] || OIDC_SCOPE }
      end

      def query_string
        URI.encode(query_params.collect { |k, v| "#{k}=#{v}" }.join('&'))
      end
    end
  end
end

OmniAuth.config.add_camelization 'azuread', 'AzureAD'
