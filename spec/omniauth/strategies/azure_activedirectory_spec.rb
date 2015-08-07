#-------------------------------------------------------------------------------
# # Copyright (c) Microsoft Open Technologies, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A
# PARTICULAR PURPOSE, MERCHANTABILITY OR NON-INFRINGEMENT.
#
# See the Apache License, Version 2.0 for the specific language
# governing permissions and limitations under the License.
#-------------------------------------------------------------------------------

require 'spec_helper'
require 'omniauth-azure-activedirectory'

# This was fairly awkward to test. I've stubbed every endpoint and am simulating
# the state of the request. Especially large strings are stored in fixtures.
describe OmniAuth::Strategies::AzureActiveDirectory do
  let(:app) { -> _ { [200, {}, ['Hello world.']] } }

  ##
  # I encoded this manually. It was super fun.
  #
  # payload:
  #   { 'iss' => 'https://sts.windows.net/bunch-of-random-chars',
  #     'name' => 'John Smith',
  #     'aud' => 'the client id',
  #     'nonce' => 'my nonce',
  #     'email' => 'jsmith@contoso.com',
  #     'given_name' => 'John',
  #     'family_name' => 'Smith' }
  # headers:
  #   { 'typ' => 'JWT',
  #     'alg' => 'RS256',
  #     'kid' => 'abc123' }
  #
  let(:id_token) { File.read(File.expand_path('../../../fixtures/id_token.txt', __FILE__)) }
  let(:x5c) { File.read(File.expand_path('../../../fixtures/x5c.txt', __FILE__)) }

  # These values were used to create the id_token JWT>
  let(:client_id) { 'the client id' }
  let(:code) { 'code' }
  let(:email) { 'jsmith@contoso.com' }
  let(:family_name) { 'smith' }
  let(:given_name) { 'John' }
  let(:issuer) { 'https://sts.windows.net/bunch-of-random-chars' }
  let(:kid) { 'abc123' }
  let(:name) { 'John Smith' }
  let(:nonce) { 'my nonce' }
  let(:session_state) { 'session state' }

  let(:hybrid_flow_params) do
    { 'id_token' => id_token,
      'session_state' => session_state,
      'code' => code }
  end

  let(:tenant) { 'tenant' }
  let(:openid_config_response) { "{\"issuer\":\"#{issuer}\",\"authorization_endpoint\":\"http://authorize.com/\"}" }
  let(:keys_response) { "{\"keys\":[{\"kid\":\"#{kid}\",\"x5c\":[\"#{x5c}\"]}]}" }

  let(:env) { { 'rack.session' => { 'omniauth-azure-activedirectory.nonce' => nonce } } }

  before(:each) do
    stub_request(:get, "https://login.windows.net/#{tenant}/.well-known/openid-configuration")
      .to_return(status: 200, body: openid_config_response)
    stub_request(:get, 'https://login.windows.net/common/discovery/keys')
      .to_return(status: 200, body: keys_response)
  end

  describe '#callback_phase' do
    let(:request) { double('Request', params: hybrid_flow_params, path_info: 'path') }
    let(:strategy) do
      described_class.new(app, client_id, tenant).tap do |s|
        allow(s).to receive(:request) { request }
      end
    end

    before(:each) { strategy.call!(env) }

    context 'with a successful response' do
      subject { -> { strategy.callback_phase } }

      # If it passes this test, then the id was successfully validated.
      it { is_expected.to_not raise_error }

      describe 'the auth hash' do
        before(:each) { strategy.callback_phase }

        subject { env['omniauth.auth'] }

        it 'should contain the name' do
          expect(subject.info['name']).to eq name
        end

        it 'should contain the first name' do
          expect(subject.info['first_name']).to eq given_name
        end

        it 'should contain the last name' do
          expect(subject.info['last_name']).to eq family_name
        end

        it 'should contain the email' do
          expect(subject.info['email']).to eq email
        end

        it 'should contain the auth code' do
          expect(subject.credentials['code']).to eq code
        end

        it 'should contain the session state' do
          expect(subject.extra['session_state']).to eq session_state
        end
      end
    end
  end
end
