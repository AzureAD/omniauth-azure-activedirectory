#-------------------------------------------------------------------------------
# Copyright (c) 2015 Micorosft Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

require 'jwt'
require 'omniauth/strategies/oauth2'
require 'openssl'
require 'securerandom'

module OmniAuth
  module Strategies
    # A strategy for authentication against Azure Active Directory.
    # rubocop:disable Metrics/ClassLength
    class AzureActiveDirectory < OmniAuth::Strategies::OAuth2
      include OmniAuth::AzureActiveDirectory

      BASE_SCOPES = %w[openid profile email].freeze
      DEFAULT_RESPONSE_MODE = 'form_post'.freeze
      DEFAULT_RESPONSE_TYPE = 'code id_token'.freeze
      DEFAULT_TENANT = 'common'.freeze

      option :name, 'azure_activedirectory'

      option :client_id, nil
      option :client_secret, nil
      option :response_mode, DEFAULT_RESPONSE_MODE
      option :response_type, DEFAULT_RESPONSE_TYPE
      option :scope, BASE_SCOPES.join(' ')
      option :tenant, DEFAULT_TENANT
      option :verify_iss, false

      credentials { { code: @code } }
      uid { claims['sub'] }

      info do
        {
          # Since name is not always present, default to oid because `name` is
          # required for an auth_hash to be valid. The name should not be used
          # for anything except display.
          name: claims['name'] || claims['oid'],
          # Email is only included in personal accounts requests. For sign-ins
          # with an AD account, the preferred_username key might be an email,
          # but not always; it could be a phone number or just a generic
          # username.
          email: claims['email'],
          preferred_username: claims['preferred_username'],
          oid: claims['oid'],
          tid: claims['tid']
        }
      end
      extra do
        { session_state: @session_state,
          raw_info:
            { id_token: @id_token,
              id_token_claims: claims,
              id_token_header: header } }
      end

      uid { claims['sub'] }

      def client
        options.client_options.authorize_url = URI(openid_config['authorization_endpoint'])
        options.client_options.token_url = URI(openid_config['token_endpoint'])

        super
      end

      def callback_url
        full_host + script_name + callback_path
      end

      def authorize_params
        options.authorize_params[:nonce] = new_nonce
        options.authorize_params[:response_mode] = options.response_mode
        options.authorize_params[:response_type] = options.response_type

        super
      end

      private

      def claims
        @claims ||= decoded_token[0]
      end

      def header
        @header ||= decoded_token[1]
      end

      def decoded_token
        @session_state = request.params['session_state']
        @id_token = access_token.params['id_token']
        @decoded_token ||= validate_and_parse_id_token(@id_token)
      end

      ##
      # Constructs a one-time-use authorize_endpoint. This method will use
      # a new nonce on each invocation.
      #
      # @return String
      def authorize_endpoint_url
        uri = URI(openid_config['authorization_endpoint'])
        uri.query = URI.encode_www_form(client_id: client_id,
                                        redirect_uri: callback_url,
                                        nonce: new_nonce)
        uri.to_s
      end

      ##
      # The client id of the calling application. This must be configured where
      # AzureAD is installed as an OmniAuth strategy.
      #
      # @return String
      def client_id
        return options.client_id if options.client_id

        raise StandardError, 'No client_id specified in AzureAD configuration.'
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
        response = JSON.parse(Net::HTTP.get(URI(signing_keys_url)))
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
        JSON.parse(
          Net::HTTP.get(
            URI(openid_config_url)
          )
        )
      rescue JSON::ParserError
        raise StandardError, 'Unable to fetch OpenId configuration for ' \
                             'AzureAD tenant.'
      end

      # The expected id token issuer taken from the discovery endpoint.
      #
      # @return String
      def issuer
        openid_config['issuer']
      end

      ##
      # Generates a new nonce for one time use. Stores it in the session so
      # multiple users don't share nonces. All nonces should be generated by
      # this method.
      #
      # @return String
      def new_nonce
        session['omniauth-azure-activedirectory.nonce'] = SecureRandom.uuid
      end

      ##
      # A memoized version of #fetch_openid_config.
      #
      # @return Hash
      def openid_config
        @openid_config ||= fetch_openid_config
      end

      ##
      # The location of the OpenID configuration for the tenant.
      #
      # @return String
      def openid_config_url
        "https://login.microsoftonline.com/#{options.tenant}/v2.0/.well-known/openid-configuration/"
      end

      ##
      # Returns the most recent nonce for the session and deletes it from the
      # session.
      #
      # @return String
      def read_nonce
        session.delete('omniauth-azure-activedirectory.nonce')
      end

      ##
      # The keys used to sign the id token JWTs. This is just a memoized version
      # of #fetch_signing_keys.
      #
      # @return Array[Hash]
      def signing_keys
        @signing_keys ||= fetch_signing_keys
      end

      ##
      # The location of the public keys of the token signer. This is parsed from
      # the OpenId config response.
      #
      # @return String
      def signing_keys_url
        return openid_config['jwks_uri'] if openid_config.include? 'jwks_uri'

        raise StandardError, 'No jwks_uri in OpenId config response.'
      end

      ##
      # Verifies the signature of the id token as well as the exp, nbf, iat,
      # iss, and aud fields.
      #
      # See OpenId Connect Core 3.1.3.7 and 3.2.2.11.
      #
      # @return Claims, Header
      #
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def validate_and_parse_id_token(id_token)
        claims, token_header =
          JWT.decode(id_token, nil, true, verify_options) do |header|
            # There should always be one key from the discovery endpoint that
            # matches the id in the JWT header.
            x5c = (signing_keys.find do |key|
              key['kid'] == header['kid']
            end || {})['x5c']
            if x5c.nil? || x5c.empty?
              raise JWT::VerificationError, 'No keys from key endpoint match the id token'
            end

            # The key also contains other fields, such as n and e, that are
            # redundant. x5c is sufficient to verify the id token.
            OpenSSL::X509::Certificate.new(JWT.base64url_decode(x5c.first)).public_key
          end

        @code = request.params['code']
        validate_chash(@code, claims, token_header)
        return claims, token_header if claims['nonce'] == read_nonce

        raise JWT::DecodeError, 'Returned nonce did not match.'
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      ##
      # Verifies that the c_hash the id token claims matches the authorization
      # code. See OpenId Connect Core 3.3.2.11.
      #
      # @param String code
      # @param Hash claims
      # @param Hash header
      def validate_chash(code, claims, header)
        return if claims['c_hash'].nil?

        # This maps RS256 -> sha256, ES384 -> sha384, etc.
        algorithm = (header['alg'] || 'RS256').sub(/RS|ES|HS/, 'sha')
        full_hash = OpenSSL::Digest.new(algorithm).digest code
        c_hash = JWT.base64url_encode full_hash[0..full_hash.length / 2 - 1]
        return if c_hash == claims['c_hash']

        raise JWT::VerificationError, 'c_hash in id token does not match auth code.'
      end

      ##
      # The options passed to the Ruby JWT library to verify the id token.
      # Note that these are not all the checks we perform. Some (like nonce)
      # are not handled by the JWT API and are checked manually in
      # #validate_and_parse_id_token.
      #
      # @return Hash
      def verify_options
        {
          aud: client.id,
          iss: issuer,
          verify_aud: true,
          verify_expiration: true,
          verify_iat: true,
          verify_iss: options.verify_iss,
          verify_not_before: true
        }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

OmniAuth.config.add_camelization 'azure_activedirectory', 'AzureActiveDirectory'
