require 'securerandom'

RSpec.describe Rester do
  describe '::connect' do
    subject { Rester.connect(*connect_args) }
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
  end # ::connect

  describe '::correlation_id' do
    subject { Rester.correlation_id }
    let(:id) { SecureRandom.uuid }

    context 'with id set beforehand' do
      before { Rester.correlation_id = id }
      it { is_expected.to eq id }
    end

    context 'with no id set beforehand' do
      it 'should create one by default' do
        is_expected.to match(/[\w]{8}(-[\w]{4}){3}-[\w]{12}/)
      end
    end
  end # ::correlation_id

  describe '::correlation_id=' do
    subject { Rester.send(:_correlation_ids) }
    before { Rester.correlation_id = id }
    let(:id) { SecureRandom.uuid }

    context 'with single thread' do
      context 'with new id' do
        it 'should set the correlation id for the current thread' do
          expect(subject[Thread.current.object_id]).to eq id
        end
      end # with new id

      context 'with nil id' do
        it 'should delete the key for the thread' do
          expect(subject[Thread.current.object_id]).to eq id
          Rester.correlation_id = nil
          expect(subject[Thread.current.object_id]).to eq nil
        end
      end # with nil id
    end # with single thread

    context 'with multiple threads' do
      before { new_thread.join }
      let(:new_thread) { Thread.new { Rester.correlation_id = new_id } }
      let(:new_id) { SecureRandom.uuid }

      context 'with new ids' do
        it 'should set the correlation id for both threads' do
          expect(subject[Thread.current.object_id]).to eq id
          expect(subject[new_thread.object_id]).to eq new_id
        end
      end # with new ids

      context 'with nil id' do
        it 'should delete the key for the current thread' do
          expect(subject[Thread.current.object_id]).to eq id
          expect(subject[new_thread.object_id]).to eq new_id
          Rester.correlation_id = nil
          expect(subject[Thread.current.object_id]).to eq nil
          expect(subject[new_thread.object_id]).to eq new_id
        end
      end # with nil id
    end # with multiple threads
  end # ::correlation_id=
end # Rester
