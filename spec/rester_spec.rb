RSpec.describe Rester do
  describe '::connect' do
    subject { client }
    let(:client) { Rester.connect(*connect_args) }
    let(:adapter) { subject.adapter }

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
      it { is_expected.to eq true }
    end # without circuit_breaker_enabled
  end # ::connect
end # Rester
