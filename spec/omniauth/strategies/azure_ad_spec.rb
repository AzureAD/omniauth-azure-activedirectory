require 'spec_helper'
require 'omniauth-azure-ad'

describe OmniAuth::Strategies::AzureAD do
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
