require 'support/local_adapter_test_service'

module Rester
  module Client::Adapters
    RSpec.describe LocalAdapter do
      let(:service) { LocalAdapterTestService }
      let(:adapter) { LocalAdapter.new(service, opts) }
      let(:opts) { {} }

      describe '::can_connect_to?' do
        subject { LocalAdapter.can_connect_to?(service) }

        context 'with non-class' do
          let(:service) { 'some string' }
          it { is_expected.to be false }
        end # with non-class

        context 'with non-Service class' do
          let(:service) { Class.new }
          it { is_expected.to be false }
        end # with non-Service class

        context 'with valid Service class' do
          let(:service) { Class.new(Service) }
          it { is_expected.to be true }
        end # with valid Service class
      end # ::can_connect_to?

      describe '#request!', :request! do
        subject { adapter.request!(verb, path, encoded_data) }
        let(:encoded_data) { Utils.encode_www_data(params) }
        let(:context) { nil }
        let(:params) { {} }

        context 'GET /v1/tests' do
          let(:verb) { :get }
          let(:path) { '/v1/tests' }

          context 'with headers' do
            before {
              adapter.headers(
                'X-Rester-Correlation-Id' => Rester.correlation_id
              )
            }

            it 'should add the headers to the request' do
              expect(service).to receive(:call).with(
                'REQUEST_METHOD' => verb.to_s.upcase,
                'PATH_INFO'      => path,
                'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
                'QUERY_STRING'   => '',
                'rack.input'     => StringIO,
                'HTTP_X_RESTER_CORRELATION_ID' => Rester.correlation_id
              ).once {
                [
                  200,
                  { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                  ''
                ]
              }
              subject
            end
          end # with headers

          context 'without query params' do
            it 'should return correct response' do
              is_expected.to eq([
                200,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"message":"no query provided"}'
              ])
            end
          end

          context 'with query provided' do
            let(:params) { { query: 'a query' } }
            it 'should return correct response' do
              is_expected.to eq([
                200,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"message":"query provided: a query"}'
              ])
            end
          end
        end # GET /v1/tests

        context 'POST /v1/tests' do
          let(:verb) { :post }
          let(:path) { '/v1/tests' }

          context 'without data' do
            it 'should return correct response' do
              is_expected.to eq([
                201,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{}'
              ])
            end
          end

          context 'with data' do
            let(:params) { { d1: 'one', d2: 2, d3: 3.3 } }
            it 'should return correct response' do
              is_expected.to eq([
                201,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"d1":"one","d2":2,"d3":3.3}'
              ])
            end
          end
        end # POST /v1/tests

        context 'GET /v1/tests/test_id' do
          let(:verb) { :get }
          let(:path) { '/v1/tests/test_id' }
          it 'should return correct response' do
            is_expected.to eq([
              200,
              { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
              '{"test_id":"test_id"}'
            ])
          end
        end

        context 'PUT /v1/tests/test_id' do
          let(:verb) { :put }
          let(:path) { '/v1/tests/test_id' }

          context 'without array param' do
            it 'should return correct response' do
              is_expected.to eq([
                200,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"test_id":"test_id"}'
              ])
            end
          end

          context 'with array param' do
            let(:params) { { a: ['one', 2, 3.3] } }
            it 'should return correct response' do
              is_expected.to eq([
                200,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"a":["one","2","3.3"],"test_id":"test_id"}'
              ])
            end
          end

          context 'with hash param' do
            let(:params) { { h: { key: 'value' } } }
            it 'should return correct response' do
              is_expected.to eq([
                200,
                { 'X-Rester-Producer-Name' => 'LocalAdapterTestService' },
                '{"h":{"key":"value"},"test_id":"test_id"}'
              ])
            end
          end
        end
      end # #request!
    end # LocalAdapter
  end # Client::Adapters
end # Rester
