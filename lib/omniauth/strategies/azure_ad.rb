require 'adal'
require 'base64'
require 'jwt'
require 'omniauth'
require 'omniauth/azure_ad/jwt'
require 'openssl'
require 'open-uri'

module OmniAuth
  module Strategies
    # A strategy for authentication against Azure Active Directory.
    class AzureAD
      include OmniAuth::AzureAD
      include OmniAuth::Strategy

      AUTH_CTX = ADAL::AuthenticationContext.new
      DEFAULT_RESPONSE_TYPE = 'code id_token'

      attr_reader :id_token
      attr_reader :session_state
      attr_reader :code
      attr_reader :error

      # TODO(aj-michael) I don't think any of this is right.
      uid { @claims[JWTClaim::SUBJECT] }
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
        parse_authorization_response unless error
        @claims, @header = JWT.decode(@id_token, nil, false)
        validate_id_token(id_token)
        super
      end

      ##
      # Constructs a one-time-use authorize_endpoint. This method will use
      # a new nonce on each invocation.
      #
      # @return String
      def authorize_endpoint
        AUTH_CTX.authorization_request_url(nil, # resource
                                           client_id,
                                           callback_url,
                                           nonce: new_nonce,
                                           response_type: response_type).to_s
      end

      ##
      # See OpenId Connect Core 3.1.3.7 and 3.2.2.11.
      #
      # 1. Validate the signature according to JWS using the `alg` header.
      # 2. Check the nonce.
      # 3. Verify the issuer matches. TODO(aj-michael) Determine where to find
      #    the true issuer.
      # 4. Validate the `aud` claim. If `aud` is a string, it must match the
      #    client id. If it is an array, it must include the client id.
      # 5. If `aud` contains multiple audiences, `azp` is required.
      # 6. If `azp` is present, it must match client id.
      # 7. Check the `exp` time.
      # 8. Do I care about `iat`?
      def validate_id_token(id_token)
        keys = fetch_signing_keys
        openid_config = fetch_openid_config

        puts "My nonce was #{read_nonce}."

        puts keys[0]
        puts openid_config


        # Decode the JWT without checking signature.
        claims, header = JWT.decode(id_token, nil, false)

        puts header
        puts header['alg']

        key = OpenSSL::PKey::RSA.new 2048
        key.e = Base64.decode64(keys[0]['e'])
        key.n = Base64.decode64(keys[0]['n'])

        JWT.decode(id_token, key)

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

      private

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
      # TODO(aj-michael) Document this.
      #
      # @return String
      def issuer
        fetch_openid_config['issuer']
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def new_nonce
        session['omniauth-azure-ad.nonce'] = SecureRandom.uuid
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
      def parse_authorization_response
        @session_state = request.params['session_state']
        @id_token = request.params['id_token']
        @code = request.params['code']
      end

      ##
      # TODO(aj-michael) Document this.
      #
      # @return String
      def response_type
        options[:response_type] || DEFAULT_RESPONSE_TYPE
      end

      ##
      # The location of the AzureAD public signing keys.
      #
      # TODO(aj-michael) This should not be static.
      #
      # @return URI
      def signing_keys_url
        URI('https://login.windows.net/common/discovery/keys')
      end
    end
  end
end

OmniAuth.config.add_camelization 'azuread', 'AzureAD'
