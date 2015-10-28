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

      it 'should send request correctly' do
        expect(subject.tests('testtoken').get).to eq(
          { token: 'testtoken', params: {}, method: 'get' }
        )
      end

      context 'with version specified' do
        let(:opts) { { version: 1234 } }

        it 'should have specified version' do
          expect(subject.adapter.version).to eq 1234
        end
      end # with version specified
    end # with service class

    context 'with file path' do
      let(:connect_args) { ['spec/stubs/dummy_stub.yml'] }

      it { is_expected.to be_a Rester::Client }

      it 'should have StubAdapter' do
        expect(subject.adapter).to be_a Rester::Client::Adapters::StubAdapter
      end

      it 'should have the correct version' do
        expect(subject.adapter.version).to eq 1.1
      end

      context 'with stub missing version' do
        let(:connect_args) { ['spec/stubs/stub_without_version.yml'] }

        it 'should default to version 1' do
          expect(subject.adapter.version).to eq 1
        end
      end

      context 'with invalid file' do
        let(:connect_args) { ['spec/stubs/invalid_stub_file.rb'] }

        it 'should raise an error' do
          expect { subject }.to raise_error Rester::Errors::InvalidStubFileError, "Expected .yml, got .rb"
        end
      end # with invalid file
    end  # with file path
  end # ::connect
end # Rester
