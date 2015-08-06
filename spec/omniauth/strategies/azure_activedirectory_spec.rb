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

describe OmniAuth::Strategies::AzureActiveDirectory do
  let(:app) { -> { [200, {}, ['Hello world.']] } }
  let(:id_token) { 'id_token' }
  let(:request) { double('Request', params: { 'id_token' => id_token }) }
  let(:client_id) { 'client id' }
  let(:tenant) { 'tenant' }

  let(:strategy) do
    described_class.new(app, client_id, tenant).tap do |s|
      allow(s).to receive(:request) { request }
    end
  end

  before(:each) do
    stub_request(:get, "https://login.windows.net/#{tenant}/.well-known/openid-configuration")
      .to_return(status: 200, body: '{"issuer":"issuer","authorization_endpoint":"http://authorize.com/"}')
  end

  describe '#request_phase' do
  end

  describe '#callback_phase' do
    context 'with an error response' do
      subject { -> { strategy.callback_phase } }

      it { is_expected.to raise_error described_class::OAuthError }
    end

    context 'with a successful response' do
    end
  end
end
