require 'securerandom'

RSpec.describe Rester do
  describe '::connect' do
    subject { client }
    let(:client) { Rester.connect(*connect_args) }
    let(:adapter) { subject.adapter }

    around { |ex|
      Rester.begin_request
      ex.run
      Rester.end_request
    }

    context 'with url' do
      let(:url) { RSpec.server_uri }
      let(:connect_args) { [url] }

      it { is_expected.to be_a Rester::Client }

      it 'should have HttpAdapter' do
        expect(adapter).to be_a Rester::Client::Adapters::HttpAdapter
      end

      it 'should have its adapter connected' do
        expect(adapter.connected?).to eq true
      end
    end

    context 'with service class' do
      let(:opts) { {} }
      let(:connect_args) { [Rester::DummyService, opts] }
      before {
        client # Prime the client so the initial ping is sent
        Rester.begin_request # Begin the request again since the service ends it
      }
      after { Rester.end_request }

      it { is_expected.to be_a Rester::Client }

      it 'should have LocalAdapter' do
        expect(adapter).to be_a Rester::Client::Adapters::LocalAdapter
        expect(adapter.service).to eq Rester::DummyService
      end

      it 'should default to version 1' do
        expect(subject.version).to eq 1
      end

      it 'should send request correctly' do
        expect(subject.tests('testtoken').get).to eq(
          { token: 'testtoken', params: {}, method: 'get' }
        )
      end

      context 'with version specified' do
        let(:opts) { { version: 1234 } }

        it 'should have specified version' do
          expect(subject.version).to eq 1234
        end
      end # with version specified

      it 'should have its adapter connected' do
        expect(adapter.connected?).to eq true
      end
    end # with service class

    context 'with file path' do
      let(:connect_args) { ['spec/stubs/dummy_stub.yml', opts] }
      let(:opts) { {version: 1.1} }

      it { is_expected.to be_a Rester::Client }

      it 'should have StubAdapter' do
        expect(adapter).to be_a Rester::Client::Adapters::StubAdapter
      end

      context 'with invalid input' do
        let(:connect_args) { ['spec/stubs/', opts] }

        it 'should raise an error' do
          expect { subject }.to raise_error 'unable to connect to "spec/stubs/"'
        end
      end # with invalid input

      it 'should have its adapter connected' do
        expect(adapter.connected?).to eq true
      end
    end  # with file path

    context 'with timeout' do
      let(:connect_args) { [RSpec.server_uri, timeout: 12.34] }

      it 'should pass timeout to adapter' do
        expect(adapter).to have_attributes(timeout: 12.34)
      end
    end # with timeout

    context 'without timeout' do
      let(:connect_args) { [RSpec.server_uri] }

      it 'should pass default timeout to adapter' do
        expect(adapter).to have_attributes(timeout: 10)
      end
    end # without timeout

    context 'with circuit_breaker_enabled' do
      subject { client.circuit_breaker_enabled? }

      context 'set to true' do
        let(:connect_args) { [RSpec.server_uri, circuit_breaker_enabled: true] }
        it { is_expected.to eq true }
      end

      context 'set to false' do
        let(:connect_args) { [RSpec.server_uri, circuit_breaker_enabled: false] }
        it { is_expected.to eq false }
      end
    end # with circuit_breaker_enabled

    context 'without circuit_breaker_enabled' do
      subject { client.circuit_breaker_enabled? }
      let(:connect_args) { [RSpec.server_uri] }

      context 'in test environment' do
        it { is_expected.to eq false }
      end

      context 'in non-test environment' do
        before {
          ENV['RACK_ENV'] = 'development'
          ENV['RAILS_ENV'] = 'development'
        }

        after {
          ENV['RACK_ENV'] = 'test'
          ENV['RAILS_ENV'] = 'test'
        }
        it { is_expected.to eq true }
      end
    end # without circuit_breaker_enabled
  end # ::connect

  describe '::service_name' do
    subject { Rester.service_name }

    it 'should default to the Rails application name' do
      is_expected.to eq "Dummy"
    end

    context 'with service_name set' do
      before { Rester.service_name = "New Consumer Name" }
      it { is_expected.to eq "New Consumer Name" }
    end # with service_name set
  end # ::service_name

  describe '::begin_request' do
    subject { Rester.request_info }
    before { Rester.begin_request }
    it { is_expected.to eq({}) }
  end # ::begin_request

  describe '::end_request' do
    subject { Rester.request_info }
    before { Rester.end_request }
    it { is_expected.to eq nil }
  end # ::end_request

  describe '::processing_request?' do
    subject { Rester.processing_request? }

    context 'with request processing' do
      before { Rester.begin_request }
      it { is_expected.to be true }
    end

    context 'with no request processing' do
      before { Rester.end_request }
      it { is_expected.to be false }
    end
  end # ::processing_request?

  describe '::request_info=' do
    subject { Rester.request_info }
    before { Rester.request_info = request_info }
    let(:request_info) {  { correlation_id: id } }
    let(:id) { SecureRandom.uuid }

    context 'with single thread' do
      context 'with new request_info' do
        it 'should set the request info value' do
          expect(subject[:correlation_id]).to eq id
        end
      end # with new request_info

      context 'with nil request_info' do
        let(:request_info) { nil }
        it { is_expected.to eq nil }
      end
    end # with single thread

    context 'with multiple threads' do
      let(:new_thread) {
        Thread.new do
          Rester.request_info = new_thread_info
          expect(Rester.request_info).to eq new_thread_info
        end
      }
      let(:new_thread_info) { { correlation_id: new_id } }
      let(:new_id) { SecureRandom.uuid }
      before { new_thread.join }

      it { expect(Rester.request_info).to eq request_info }

      context 'with nil id' do
        it 'should delete the key for the current thread' do
          expect(Rester.request_info).to eq request_info
          Rester.request_info = nil
          expect(Rester.request_info).to eq nil
        end
      end # with nil id
    end # with multiple threads
  end # ::request_info=

  describe '::correlation_id' do
    subject { Rester.correlation_id }

    context 'with correlation id set' do
      before { Rester.request_info = {correlation_id: id } }
      let(:id) { SecureRandom.uuid }
      it { is_expected.to eq id }
    end # with correlation id set

    context 'with correlation_id not set' do
      before { Rester.end_request }
      it { is_expected.to eq nil }
    end # with correlation_id not set
  end # ::correlation_id

  describe '::correlation_id=' do
    subject { Rester.request_info[:correlation_id] }
    before {
      Rester.request_info = {}
      Rester.correlation_id = id
    }
    let(:id) { SecureRandom.uuid }
    it { is_expected.to eq id }
  end # ::correlation_id=

  describe '::logger', :logger do
    subject { Rester.logger }

    context 'without logger defined' do
      it { is_expected.to be_a Rester::Utils::LoggerWrapper }
    end

    context 'with logger set to nil' do
      before { Rester.logger = nil }
      it { is_expected.to be_a Rester::Utils::LoggerWrapper }
    end

    context 'with logger set to STDOUT logger' do
      let(:logger) { Logger.new(STDOUT) }
      before { Rester.logger = logger }
      it { expect(subject.logger).to eq logger }
    end
  end # ::logger
end # Rester
