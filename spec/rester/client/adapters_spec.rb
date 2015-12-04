module Rester
  class Client
    RSpec.describe Adapters do
      include Adapters

      describe '::list' do
        subject { Adapters.list }

        it 'should return expected list' do
          is_expected.to eq(
            [
              Adapters::HttpAdapter,
              Adapters::LocalAdapter,
              Adapters::StubAdapter
            ]
          )
        end
      end # ::list

      describe '::connect', :connect do
        let(:opts) { {} }
        subject { Adapters.connect(service, opts) }

        context 'with url' do
          let(:service) { RSpec.server_uri.to_s }

          it { is_expected.to be_a Rester::Client::Adapters::HttpAdapter }
          it { is_expected.to have_attributes(connected?: true) }

          it 'should be connected to correct url' do
            expect(subject.connection.url.to_s).to eq service
          end
        end # with url

        context 'with URI object' do
          let(:service) { RSpec.server_uri }

          it { is_expected.to be_a Rester::Client::Adapters::HttpAdapter }
          it { is_expected.to have_attributes(connected?: true) }

          it 'should be connected to correct url' do
            expect(subject.connection.url).to eq service
          end
        end # with URI object

        context 'with service class' do
          let(:service) { DummyService }

          it { is_expected.to be_a Rester::Client::Adapters::LocalAdapter }
          it { is_expected.to have_attributes(connected?: true) }

          it 'should have be connected to DummyService' do
            expect(subject.service).to eq Rester::DummyService
          end
        end # with service class

        context 'with file path' do
          let(:service) { 'spec/stubs/dummy_stub.yml' }

          it { is_expected.to be_a Rester::Client::Adapters::StubAdapter }
          it { is_expected.to have_attributes(connected?: true) }

          it 'should have be connected to correct stub file' do
            expect(subject.stub.path).to eq service
          end
        end

        context 'with timeout' do
          let(:opts) { { timeout: 1234.1234 } }
          let(:service) { RSpec.server_uri.to_s }
          it { is_expected.to have_attributes(timeout: 1234.1234) }
        end # with timeout

        context 'without timeout specified' do
          let(:opts) { {} }
          let(:service) { RSpec.server_uri.to_s }
          it { is_expected.to have_attributes(timeout: nil) }
        end # without timeout specified
      end # ::connect

      describe '::extract_opts', :extract_opts do
        subject { Adapters.extract_opts(opts) }

        context 'with empty hash' do
          let(:opts) { {} }
          it { is_expected.to eq Adapters::DEFAULT_OPTS }
        end # with empty hash

        context 'with timeout specified' do
          let(:opts) { { timeout: 12.34 } }
          it { is_expected.to eq(timeout: 12.34) }

          it 'should have extracted the timeout' do
            subject
            expect(opts).to eq({})
          end
        end # with timeout specified
      end # ::extract_opts
    end # Adapters
  end # Client::Adapters
end # Rester
