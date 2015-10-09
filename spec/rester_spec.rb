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
      let(:connect_args) { [Rester::DummyService] }

      it { is_expected.to be_a Rester::Client }

      it 'should have LocalAdapter' do
        expect(subject.adapter).to be_a Rester::Client::Adapters::LocalAdapter
        expect(subject.adapter.service).to eq Rester::DummyService
      end
    end
  end # ::connect
end # Rester
