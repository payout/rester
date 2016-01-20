module Rester
  RSpec.describe Client do
    ##
    # Converts a hash into a hash that would be returned by the client.
    # Essentially, this is mostly to convert symbol values into strings.
    def json_h(params)
      JSON.parse(params.to_json, symbolize_names: true)
    end

    let(:client) { Client.new(adapter, client_opts) }
    let(:adapter) { Client::Adapters::HttpAdapter.new.tap { |a|
      a.connect(test_url)
    }}

    let(:client_opts) do
      {
        version: version,
        error_threshold: error_threshold,
        retry_period: retry_period,
        logger: logger,
        circuit_breaker_enabled: circuit_breaker_enabled
      }
    end

    let(:version) { 1 }
    let(:error_threshold) { nil }
    let(:retry_period) { nil }
    let(:logger) { nil }
    let(:circuit_breaker_enabled) { true }

    let(:test_url) { RSpec.server_uri.to_s }

    # Request Hash
    let(:req_hash) { {string: "string", integer: 1, float: 1.1, symbol: :symbol, bool: true, null: nil} }

    # Response Hash
    let(:res_hash) { req_hash.map{|k,v| [k, v.nil? ? nil : v.to_s]}.to_h }

    describe '#connected?', :connected? do
      subject { client.connected? }

      context 'after connecting' do
        before { adapter.connect(test_url) }
        it { is_expected.to be true }
      end
    end # #connected?

    describe '#version', :version do
      subject { client.version }

      context 'with no version passed to client' do
        let(:client_opts) { {} }
        it { is_expected.to eq 1 }
      end

      context 'with version passed as nil' do
        let(:version) { nil }
        it { is_expected.to eq 1 }
      end

      context 'with version passed as 1' do
        let(:version) { 1 }
        it { is_expected.to eq 1 }
      end

      context 'with version passed as 10' do
        let(:version) { 10 }
        it { is_expected.to eq 10 }
      end

      context 'with version passed as "10"' do
        let(:version) { "10" }
        it { is_expected.to eq 10 }
      end

      context 'with version passed as -1' do
        let(:version) { -1 }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error ArgumentError, 'version must be > 0'
        end
      end # with version passed as -1
    end # #version

    describe '#error_threshold', :error_threshold do
      subject { client.error_threshold }

      context 'with no error_threshold passed to client' do
        let(:client_opts) { {} }
        it { is_expected.to eq 3 }
      end

      context 'with error_threshold passed as nil' do
        let(:error_threshold) { nil }
        it { is_expected.to eq 3 }
      end

      context 'with error_threshold passed as 10' do
        let(:error_threshold) { 10 }
        it { is_expected.to eq 10 }
      end

      context 'with error_threshold passed as 0.001' do
        let(:error_threshold) { 0.001 }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error ArgumentError,
            'threshold must be > 0'
        end
      end # with error_threshold passed as 0.001
    end # #error_threshold

    describe '#retry_period', :retry_period do
      subject { client.retry_period }

      context 'with no retry_period passed to client' do
        let(:client_opts) { {} }
        it { is_expected.to eq 1 }
      end

      context 'with retry_period passed as nil' do
        let(:retry_period) { nil }
        it { is_expected.to eq 1 }
      end

      context 'with retry_period passed as 10' do
        let(:retry_period) { 10 }
        it { is_expected.to eq 10 }
      end

      context 'with retry_period passed as 0.001' do
        let(:retry_period) { 0.001 }
        it { is_expected.to eq 0.001 }
      end

      context 'with retry_period passed as -1' do
        let(:retry_period) { -1 }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error ArgumentError,
            'retry_period must be > 0'
        end
      end # with retry_period passed as -1
    end # #retry_period

    describe '#logger', :logger do
      subject { client.logger }

      context 'with no logger passed to client' do
        let(:client_opts) { {} }
        it { is_expected.to be_a Logger }
      end

      context 'with logger passed as nil' do
        let(:logger) { nil }
        it { is_expected.to be_a Logger }
      end

      context 'with logger passed as 10' do
        let(:logger) { Logger.new(STDOUT) }
        it { is_expected.to eq logger }
      end
    end # #logger

    describe '#request', :request do
      let(:adapter) { double('adapter') }
      let(:valid_response) {
        [200, { 'http_x_rester_producer_name' => ["DummyService"]}, '']
      }
      subject { client.request(verb, path, params) }
      before do
        # Setup setup_adapter
        allow(adapter).to receive(:connected?).and_return true
        allow(adapter).to receive(:request).and_return valid_response
        allow(adapter).to receive(:headers)
        allow(logger).to receive(:info).at_least(2).times if defined?(logger)
        client # prime the client so the initial ping connection occurs
      end

      let(:verb) { :get }
      let(:path) { '/ping' }
      let(:params) { {} }

      ##
      # Simulates a request that raises an error.
      # Useful when testing the circuit breaker logic.
      def error_request
        allow(adapter).to receive(:request).and_raise 'error'
        expect { subject }.to raise_error
      end

      ##
      # Simulates a request that does not raise an error.
      # Useful when testing the circuit breaker logic.
      def success_request
        allow(adapter).to receive(:request).and_return valid_response
        expect(subject).to eq Client::Response.new(200, {})
      end

      def success_without_producer_header
        allow(adapter).to receive(:request).and_return [200, {}, '']
        expect(subject).to eq Client::Response.new(200, {})
      end

      def let_retry_period_pass
        sleep(retry_period * 2)
      end

      context 'with error_threshold reached' do
        let(:logger) { double('logger') }
        let(:error_threshold) { 3 }
        before {
          allow(logger).to receive(:info).at_least(error_threshold).times
          (error_threshold - 1).times { error_request }
        }
        after { error_request }

        it 'should log that circuit is now opened' do
          expect(logger).to receive(:error).with(
            "Correlation-ID=#{Rester.correlation_id}: circuit opened for DummyService"
          ).once
        end
      end # with error_threshold reached

      context 'with circuit breaker disabled' do
        let(:error_threshold) { 1 }
        let(:circuit_breaker_enabled) { false }

        context 'with error_threshold reached' do
          let(:logger) { double('logger') }
          before { (error_threshold - 1).times { error_request } }
          after { error_request }

          it 'should not log that circuit is now opened' do
            expect(logger).not_to receive(:error).with('circuit opened')
          end
        end

        context 'with error_threshold already reached' do
          let(:error_threshold) { 3 }
          before { error_threshold.times { error_request } }

          it 'should raise the underlying error' do
            expect { subject }.to raise_error 'error'
          end
        end
      end # with circuit breaker disabled

      context 'with error_threshold already reached' do
        let(:error_threshold) { 3 }
        before { error_threshold.times { error_request } }
        it { expect { subject }.to raise_error Errors::CircuitOpenError }
      end

      context 'with success after retry_period passed' do
        let(:logger) { double('logger') }
        let(:error_threshold) { 3 }
        let(:retry_period) { 0.001 }

        before {
          # 3 error request logs + 1 success req log + 1 success response log
          expect(logger).to receive(:info).at_most(error_threshold + 2).times
          error_threshold.times { error_request }
        }
        after { let_retry_period_pass; success_request }

        it 'should log that circuit is now closed' do
          expect(logger).to receive(:info).with(
            "Correlation-ID=#{Rester.correlation_id}: circuit closed for DummyService"
          ).once
        end
      end # with error_threshold reached

      context 'before first real request' do
        before { success_request }

        it 'should default producer name to to the service after first ping' do
          expect(client.send(:_producer_name)).to eq "DummyService"
        end
      end # without producer name set

      context 'with producer name set' do
        before { success_request }

        it 'should default producer name to "Producer"' do
          expect(client.send(:_producer_name)).to eq "DummyService"
        end
      end # with producer name set

      context 'with successful request' do
        let(:logger) { double('logger') }
        after { success_request }

        it 'should log the correct messages' do
          expect(logger).to receive(:info).with(
            "Correlation-ID=#{Rester.correlation_id}: [Dummy] -> DummyService - GET /v1/ping"
          ).once
          expect(logger).to receive(:info).with(
            "Correlation-ID=#{Rester.correlation_id}: [Dummy] <- DummyService - GET /v1/ping 200"
          ).once
        end
      end # with successful request

      context 'with client request_handler middleware simulation' do
        let(:logger) { double('logger') }
        before {
          Rester.begin_request
          Rester.correlation_id = SecureRandom.uuid
        }
        after {
          success_request
          Rester.end_request
        }

        it 'should log the correct messages' do
          expect(logger).to receive(:info).with(
            "Correlation-ID=#{Rester.correlation_id}: [Dummy] -> DummyService - GET /v1/ping"
          ).once
          expect(logger).to receive(:info).with(
            "Correlation-ID=#{Rester.correlation_id}: [Dummy] <- DummyService - GET /v1/ping 200"
          ).once
        end
      end # with client request_handler middleware simulation
    end # #request

    describe '#tests', :tests do
      let(:tests) { client.tests(*args) }
      subject { tests }
      context 'without connection' do
        let(:adapter) { Client::Adapters::HttpAdapter.new }

        context 'with string argument' do
          let(:args) { ['token'] }

          describe '#get' do
            subject { tests.get }
            it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
          end

          describe '#update' do
            subject { tests.update }
            it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
          end

          describe '#delete' do
            subject { tests.delete }
            it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
          end
        end # with string argument

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
        end # with hash argument
      end # without connection

      context 'with connection' do
        before { adapter.connect(test_url) }

        context 'with unsupported version' do
          let(:version) { 2 }
          let(:args) { ['token'] }

          it 'should raise an error' do
            expect { subject.get }.to raise_error Errors::NotFoundError, '/v2/tests/token'
          end
        end # with unsupported version

        context 'with supported version' do
          context 'with string argument' do
            let(:args) { ['token'] }

            it { is_expected.to be_a Rester::Client::Resource }

            describe '#get' do
              let(:params) { {} }
              let(:expected_resp) { {token: 'token', params: json_h(params), method: 'get'} }

              context 'without argument' do
                subject { tests.get }
                it { is_expected.to eq(expected_resp) }
              end # without argument

              context 'with argument' do
                let(:params) { {} }
                subject { tests.get(params) }
                it { is_expected.to eq(expected_resp) }

                context 'with params' do
                  let(:params) { req_hash }

                  it 'should be successful' do
                    expect(subject.successful?).to be true
                  end

                  it { is_expected.to eq(expected_resp) }
                end

                context 'with triggered error!' do
                  let(:params) { {string: 'testing_error'} }

                  it 'should be unsuccessful' do
                    expect(subject.successful?).to be false
                  end

                  it 'should have an error message' do
                    expect(subject[:error]).to eq 'testing_error'
                    expect(subject.key?(:message)).to be false
                  end

                  context 'with message' do
                    let(:params) { {string: 'testing_error_with_message'} }

                    it 'should have an error message' do
                      expect(subject[:error]).to eq 'testing_error'
                      expect(subject[:message]).to eq 'with_message'
                    end
                  end
                end

                context 'with nil argument' do
                  let(:params) { nil }
                  it { is_expected.to eq(token: 'token', params: {}, method: 'get') }
                end
              end # with argument
            end # #get

            describe '#update' do
              let(:params) { {} }
              let(:expected_resp) {
                {
                  method: 'update',
                  int: 1, float: 1.1, bool: true, null: nil,
                  params: json_h(params.merge(test_token: 'token'))
                }
              }

              context 'without argument' do
                subject { tests.update }
                it { is_expected.to eq expected_resp }
              end # without argument

              context 'with argument' do
                subject { tests.update(params) }

                context 'with empty params' do
                  let(:params) { {} }
                  it { is_expected.to eq expected_resp }
                end

                context 'with params' do
                  let(:params) { req_hash }
                  it { is_expected.to eq expected_resp }
                end
              end # with argument
            end # #update

            describe '#delete' do
              let(:params) { {} }
              let(:expected_resp) { {token: 'token', params: json_h(params), method: 'delete'} }

              context 'without argument' do
                subject { tests.delete }
                it { is_expected.to eq(expected_resp) }
              end # without argument

              context 'with argument' do
                let(:params) { {} }
                subject { tests.delete(params) }

                before { adapter.connect(test_url) }
                it { is_expected.to eq expected_resp }

                context 'with params' do
                  let(:params) { req_hash }
                  it { is_expected.to eq expected_resp }
                end
              end # with argument
            end # #delete

            describe '#mounted_objects' do
              let(:mounted_objects) { tests.mounted_objects(*margs) }

              context 'with mounted object token' do
                let(:margs) { ['mounted_id'] }

                describe '#update' do
                  let(:params) { req_hash }
                  subject { mounted_objects.update(params) }
                  it { is_expected.to eq res_hash.merge(test_token: 'token', mounted_object_id: 'mounted_id') }
                end # #update

                describe '#delete' do
                  subject { mounted_objects.delete }
                  it { is_expected.to eq(no: 'params accepted') }
                end # #delete

                # Multi-level
                describe '#mounted_objects' do
                  subject { mounted_objects.mounted_objects('mounted_id2').get }
                  it { is_expected.to eq(test_token: 'token', mounted_object_id: 'mounted_id2') }
                end
              end # with mounted object token
            end # mounted_object

            describe '#mounted_objects!' do
              let(:mounted_objects!) { tests.mounted_objects!(arg: 'required') }
              subject { mounted_objects! }

              it 'should raise an error' do
                expect { subject.get }.to raise_error Errors::NotFoundError,
                  '/v1/tests/token/mounted_objects'
              end
            end # mounted_objects!
          end # with string argument

          context 'with hash argument' do
            let(:args) { [req_hash] }
            it { is_expected.to eq json_h(req_hash).merge(method: 'search') }
          end # with hash argument

          context 'with no arguments' do
            let(:args) { [] }
            it { is_expected.to eq(method: 'search') }
          end # with no arguments
        end # with supported version
      end # with connection
    end # #tests

    describe '#tests!', :tests! do
      let(:tests!) { client.tests!(*args) }
      subject { tests! }

      context 'without connection' do
        let(:adapter) { Client::Adapters::HttpAdapter.new }

        context 'with no arguments' do
          let(:args) { [] }
          it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
        end

        context 'with hash argument' do
          let(:args) { [{}] }
          it { expect { subject }.to raise_error Rester::Errors::ConnectionError }
        end
      end # without connection

      context 'with connection' do
        before { adapter.connect(test_url) }

        context 'with no arguments' do
          let(:args) { [] }
          it { is_expected.to eq(method: 'create') }
        end

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { is_expected.to eq json_h(req_hash).merge(method: 'create') }
        end # with hash argument
      end # with connection
    end # #tests!

    describe '#with_context' do
      let(:stub_file_path) { 'spec/stubs/dummy_stub.yml' }
      let(:context) { 'some_context' }

      context 'with StubAdapter' do
        let(:client) { Client.new(Client::Adapters::StubAdapter.new(stub_file_path)) }

        it 'should send the method down to its stub_adapter' do
          expect(client.adapter).to receive(:with_context).with(context).once
          client.with_context(context) {}
        end
      end # with StubAdapter
    end # #with_context
  end # Client
end # Rester
