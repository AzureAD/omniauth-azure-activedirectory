require 'jwt'
require 'omniauth'
require 'openssl'

module OmniAuth
  module Strategies
    # A strategy for authentication against Azure Active Directory.
    class AzureAD
      include OmniAuth::AzureAD
      include OmniAuth::Strategy

      DEFAULT_RESPONSE_TYPE = 'code id_token'
      DEFAULT_RESPONSE_MODE = 'form_post'
      DEFAULT_SIGNING_KEYS_URL =
        'https://login.windows.net/common/discovery/keys'

      attr_reader :id_token
      attr_reader :session_state
      attr_reader :code
      attr_reader :error

      # TODO(aj-michael) I don't think any of this is right.
      uid { @claims['sub'] }
      info { @claims }
      extra { { session_state: @session_state } }

      ##
      # TODO(aj-michael) Document this.
      #
      def request_phase
        redirect authorize_endpoint
      end

      ##
      # This is called by OmniAuth after the user enters credentials at the
      # authorization endpoint. OmniAuth exposes a Rack::Request object in the
      # global scope called `request`. The `request.params` field is a hash that
      # contains the content of the posted form.
      def callback_phase
        # TODO(aj-michael) Determine a better way to handle error responses.
        error = request.params['error']
        @claims = {}
        @session_state = request.params['session_state']
        @id_token = request.params['id_token']
        @code = request.params['code']
        @claims, @header = validate_id_token(id_token)
        super
      end


      private


      ##
      # Constructs a one-time-use authorize_endpoint. This method will use
      # a new nonce on each invocation.
      #
      # @return String
      def authorize_endpoint
        uri = URI(openid_config['authorization_endpoint'])
        uri.query = URI.encode_www_form(client_id: client_id,
                                        redirect_uri: callback_url,
                                        response_mode: response_mode,
                                        response_type: response_type,
                                        nonce: new_nonce)
        uri.to_s
      end

      ##
      # Note that callback_url, full_host, script_name and query_string are
      # methods defined on OmniAuth::Strategy.
      #
      # TODO(aj-michael) This is probably wrong.
      #
      # @return String
      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      ##
      # The client id of the calling application. This must be configured where
      # AzureAD is installed as an OmniAuth strategy.
      #
      # Example config.ru:
      #
      #    require 'omniauth-azure-ad'
      #
      #    use OmniAuth::Strategies::AzureAD,
      #      client_id: '<insert client id here>'
      #
      # @return String
      def client_id
        return options[:client_id] if options.include? :client_id
        fail StandardError, 'No client_id specified in AzureAD configuration.'
      end

      ##
      # The expected id token issuer taken from the discovery endpoint.
      #
      # @return String
      def issuer
        openid_config['issuer']
      end

      ##
      # Fetches the current signing keys for Azure AD. Note that there should
      # always two available, and that they have a 6 week rollover.
      #
      # Each key is a hash with the following fields:
      #   kty, use, kid, x5t, n, e, x5c
      #
      # @return Array[Hash]
      def fetch_signing_keys
        response = JSON.parse(Net::HTTP.get(signing_keys_url))
        response['keys']
      rescue JSON::ParserError
        raise StandardError, 'Unable to fetch AzureAD signing keys.'
      end

      ##
      # Fetches the OpenId Connect configuration for the AzureAD tenant. This
      # contains several import values, including:
      #
      #   authorization_endpoint
      #   token_endpoint
      #   token_endpoint_auth_methods_supported
      #   jwks_uri
      #   response_types_supported
      #   response_modes_supported
      #   subject_types_supported
      #   id_token_signing_alg_values_supported
      #   scopes_supported
      #   issuer
      #   claims_supported
      #   microsoft_multi_refresh_token
      #   check_session_iframe
      #   end_session_endpoint
      #   userinfo_endpoint
      #
      # @return Hash
      def fetch_openid_config
        JSON.parse(Net::HTTP.get(openid_config_url))
      rescue JSON::ParserError
        raise StandardError, 'Unable to fetch OpenId configuration for ' \
                             'AzureAD tenant.'
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def new_nonce
        session['omniauth-azure-ad.nonce'] = SecureRandom.uuid
      end

      ##
      # A memoized version of #fetch_openid_config.
      #
      # @return Hash
      def openid_config
        @openid_config ||= fetch_openid_config
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def read_nonce
        session.delete('omniauth-azure-ad.nonce')
      end

      ##
      # The location of the OpenID configuration for the tenant.
      #
      # TODO(aj-michael) This should not be static.
      #
      # @return URI
      def openid_config_url
        URI('https://login.windows.net/adamajmichael.onmicrosoft.com/.well-known/openid-configuration')
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def response_type
        options[:response_type] || DEFAULT_RESPONSE_TYPE
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def response_mode
        options[:response_mode] || DEFAULT_RESPONSE_MODE
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return TODO(aj-michael)
      def signing_keys
        @signing_keys ||= fetch_signing_keys
      end

      ##
      # The location of the AzureAD public signing keys. In reality, this is
      # static but since it could change in the future, we try and parse it from
      # the discovery endpoint if possible.
      #
      # @return URI
      def signing_keys_url
        if openid_config.include? 'jwks_uri'
          URI(openid_config['jwks_uri'])
        else
          URI(DEFAULT_SIGNING_KEYS_URL)
        end
      end

      ##
      # Verifies the signature of the id token as well as the exp, nbf, iat,
      # iss, and aud fields.
      #
      # See OpenId Connect Core 3.1.3.7 and 3.2.2.11.
      #
      # return Claims, Header
      def validate_id_token(id_token)
        keys = fetch_signing_keys

        verify_options = {
          verify_expiration: true,
          verify_not_before: true,
          verify_iat: true,
          verify_iss: true,
          'iss' => issuer,
          verify_aud: true,
          'aud' => client_id
        }

        # The second parameter is the public key to verify the signature.
        # However, that key is overridden by the value of the executed block
        # if one is present.
        claims, header =
          JWT.decode(id_token, nil, true, verify_options) do |header|
            # There should always be one key from the discovery endpoint that
            # matches the id in the JWT header.
            x5c = keys.select do |key|
              key['kid'] == header['kid']
            end.first['x5c'].first
            # The key also contains other fields, such as n and e, that are
            # redundant. x5c is sufficient to verify the id token.
            OpenSSL::X509::Certificate.new(JWT.base64url_decode(x5c)).public_key
          end
        return claims, header if claims['nonce'] == read_nonce
        fail JWT::DecodeError, 'Returned nonce did not match.'
      end
    end
  end
end

OmniAuth.config.add_camelization 'azuread', 'AzureAD'
