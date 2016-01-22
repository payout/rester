module Rester
  module Client::Adapters
    RSpec.describe HttpAdapter do
      let(:url) { RSpec.server_uri.to_s }
      let(:adapter_opts) { {} }
      let(:adapter) { HttpAdapter.new(url, adapter_opts) }

      describe '::can_connect_to?' do
        subject { HttpAdapter.can_connect_to?(service) }
        let(:service) { '' }

        context 'with http url' do
          let(:service) { 'http://www.google.com' }
          it { is_expected.to be true }
        end # with http url

        context 'with https url' do
          let(:service) { 'https://www.whatever.com' }
          it { is_expected.to be true }
        end # with https url

        context 'with invalid url string' do
          let(:service) { 'mybuttisonfire' }
          it { is_expected.to be false }
        end # with invalid url string

        context 'with unsupported url scheme' do
          let(:service) { 'ftp://www.whatever.com' }
          it { is_expected.to be false }
        end # with unsupported url scheme

        context 'with http URI object' do
          let(:service) { URI('http://www.google.com') }
          it { is_expected.to be true }
        end # with http URI object

        context 'with https URI object' do
          let(:service) { URI('https://www.google.com') }
          it { is_expected.to be true }
        end # with https URI object

        context 'with invalid URI scheme' do
          let(:service) { URI('ftp://www.google.com') }
          it { is_expected.to be false }
        end # with invalid URI scheme
      end # ::can_connect_to?

      describe '#request!', :request! do
        let(:params) { nil }
        let(:encoded_data) { Utils.encode_www_data(params) }
        subject { adapter.request!(verb, path, params) }

        context 'with valid request' do
          let(:verb) { :get }
          let(:path) { '/v1/commands/sleep' }
          let(:headers) { subject[1] }

          it 'should respond with the correct custom headers' do
            expect(headers).to include(
              "X-Rester-Producer-Name"=> "DummyService"
            )
          end
        end # with valid request

        context 'with request timeout' do
          let(:verb) { :get }
          let(:path) { '/v1/commands/sleep' }
          let(:adapter_opts) { { timeout: 0.001 } }

          it 'should raise timeout error' do
            expect { subject }.to raise_error Errors::TimeoutError
          end
        end # with request timeout
      end # #request!
    end # HttpAdapter
  end # Client::Adapters
end # Rester
