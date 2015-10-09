RSpec.describe Rester do
  describe '::connect' do
    subject { Rester.connect(*connect_args) }

    context 'with url' do
      let(:url) { RSpec.server_uri }
      let(:connect_args) { [url] }

      it { is_expected.to be_a Rester::Client }

      it 'should have HttpAdapter' do
        expect(subject.adapter).to be_a Rester::Client::Adapters::HttpAdapter
      end
    end

    context 'with service class' do
      let(:opts) { {} }
      let(:connect_args) { [Rester::DummyService, opts] }

      it { is_expected.to be_a Rester::Client }

      it 'should have LocalAdapter' do
        expect(subject.adapter).to be_a Rester::Client::Adapters::LocalAdapter
        expect(subject.adapter.service).to eq Rester::DummyService
      end

      it 'should default to version 1' do
        expect(subject.adapter.version).to eq 1
      end

      context 'with version specified' do
        let(:opts) { { version: 1234 } }

        it 'should have specified version' do
          expect(subject.adapter.version).to eq 1234
        end
      end # with version specified
    end # with service class
  end # ::connect
end # Rester
