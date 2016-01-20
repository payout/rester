module Rester
  module Client::Adapters
    RSpec.describe StubAdapter do
      let(:stub_file_path) { 'spec/stubs/stub_adapter_test_stub.yml' }
      let(:stub_adapter) { StubAdapter.new(stub_file_path, opts) }
      let(:opts) { {} }

      describe '::can_connect_to?' do
        subject { StubAdapter.can_connect_to?(service) }
        let(:service) { '' }

        context 'with non-string' do
          let(:service) { DummyService }
          it { is_expected.to be false }
        end # with non-string

        context 'with valid file path' do
          let(:service) { stub_file_path }
          it { is_expected.to be true }
        end # with valid file path

        context 'with invalid directory path' do
          let(:service) { 'spec/stubs' }
          it { is_expected.to be false }
        end # with invalid directory path
      end # ::can_connect_to?

      describe '#connected?' do
        subject { stub_adapter.connected? }
        it { is_expected.to eq true }
      end # #connected?

      describe '#request!', :request! do
        subject { stub_adapter.request!(verb, path, encoded_data) }
        let(:encoded_data) { Utils.encode_www_data(params) }
        let(:context) { nil }
        let(:params) { {} }

        around { |ex| stub_adapter.with_context(context) { ex.run } }

        context 'GET /ping' do
          let(:verb) { :get }
          let(:path) { '/ping' }
          it { is_expected.to eq [
            200,
            { 'X-Rester-Producer-Name' => 'some_producer' },
            '']
          }
        end # GET /ping

        context 'GET /v1/tests' do
          let(:verb) { :get }
          let(:path) { '/v1/tests' }

          context 'without query params' do
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"no query params specified"}']
            }
          end

          context 'with no query params and context = "With error response"' do
            let(:context) { 'With error response' }
            it { is_expected.to eq [
              400,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"error":"a_test_error"}']
            }
          end

          context 'with 3 query params' do
            let(:params) { { p1: 'one', p2: 2, p3: 3.3 } }
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"one, 2, 3.3"}']
            }
          end

          context 'with 3 query params and context = "With error response and three params"' do
            let(:params) { { p1: 'one', p2: 2, p3: 3.3 } }
            let(:context) { 'With error response and three params' }

            it { is_expected.to eq [
              400,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"error":"error_with_multiple_params"}']
            }
          end

          context 'with array param and context specified' do
            let(:context) { 'With array param' }
            let(:params) { { array: ['one', 'two', 'three'] } }
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"array_received"}']
            }
          end

          context 'with hash param and context specified' do
            let(:context) { 'With hash param' }
            let(:params) { { hash: { p1: 'one', p2: 2, p3: 3.3 } } }
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"hash_received"}']
            }
          end

          context 'with array param and without context specified' do
            let(:params) { { array: ['one', 'two', 'three'] } }
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"array_received"}']
            }
          end

          context 'with hash param and without context specified' do
            let(:params) { { hash: { p1: 'one', p2: 2, p3: 3.3 } } }
            it { is_expected.to eq [
              200,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"hash_received"}']
            }
          end

          context 'with undefined context' do
            let(:context) { 'this context is not defined' }

            it 'should raise StubError' do
              expect { subject }.to raise_error Errors::StubError,
                "GET /v1/tests with context '#{context}' not found"
            end
          end

          context 'with no params and context = "With three query params"' do
            let(:context) { 'With three query params' }

            it 'should raise StubError' do
              expect { subject }.to raise_error Errors::StubError,
                'GET /v1/tests with context \'With three query params\' '\
                'params don\'t match stub: "p1" should equal "one" but got '\
                'nil, "p2" should equal "2" but got nil, "p3" should equal '\
                '"3.3" but got nil'
            end
          end

          context 'with unexpected param' do
            let(:params) { { p1: 'one', p2: 'two', p3: 'three' } }
            let(:context) { 'Without any request params' }

            it 'should raise StubError' do
              expect { subject }.to raise_error Errors::StubError,
                'GET /v1/tests with context \'Without any request params\' '\
                'params don\'t match stub: received unexpected key(s): '\
                '"p1", "p2", "p3"'
            end
          end

          context 'with incorrect and extra params' do
            let(:params) { { extra: 'param', p1: 'seven', p2: 'two', p3: 3.3 } }
            let(:context) { 'With three query params' }

            it 'should raise StubError' do
              expect { subject }.to raise_error Errors::StubError,
                'GET /v1/tests with context \'With three query params\' '\
                'params don\'t match stub: "p1" should equal "one" but got '\
                '"seven", "p2" should equal "2" but got "two", and received '\
                'unexpected key(s): "extra"'
            end
          end
        end # GET /v1/tests

        context 'POST /v1/tests' do
          let(:verb) { :post }
          let(:path) { '/v1/tests' }

          context 'without body' do
            it { is_expected.to eq [
              201,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"posted without body"}']
            }
          end

          context 'with body' do
            let(:params) { { p1: 'one', p2: 2, p3: 3.3 } }
            it { is_expected.to eq [
              201,
              { 'X-Rester-Producer-Name' => 'some_producer' },
              '{"message":"posted with body"}']
            }
          end
        end # POST /v1/tests

        context 'GET /undefined_path' do
          let(:verb) { :get }
          let(:path) { '/undefined_path' }

          it 'should raise StubError' do
            expect { subject }.to raise_error Errors::StubError,
              '/undefined_path not found'
          end
        end

        context 'GET /no_verbs_defined' do
          let(:verb) { :get }
          let(:path) { '/no_verbs_defined' }

          it 'should raise StubError' do
            expect { subject }.to raise_error Errors::StubError,
              'GET /no_verbs_defined not found'
          end
        end
      end # #request!
    end # StubAdapter
  end # Client::Adapters
end # Rester
