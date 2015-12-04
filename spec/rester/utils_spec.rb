module Rester
  RSpec.describe Utils do
    describe '::stringify_vals' do
      subject { Utils.stringify_vals(hash) }

      context 'with empty hash' do
        let(:hash) { {} }
        it { is_expected.to eq({}) }
      end # with empty hash

      context 'with mock value' do
        let(:value) { double('double') }
        let(:hash) { { key: value } }

        it 'should receive #to_s' do
          expect(value).to receive(:to_s).with(no_args).once
          subject
        end
      end # with mock value

      context 'with string value' do
        let(:hash) { { key: 'value' } }
        it { is_expected.to eq hash }
      end # with string value

      context 'with symbol value' do
        let(:hash) { { key: :value } }
        it { is_expected.to eq(key: 'value') }
      end # with symbol value

      context 'with float value' do
        let(:hash) { { key: 3.14159 } }
        it { is_expected.to eq(key: '3.14159') }
      end # with float value

      context 'with integer value' do
        let(:hash) { { key: 1234 } }
        it { is_expected.to eq(key: '1234') }
      end # with integer value

      context 'with nil value' do
        let(:hash) { { key: nil } }
        it { is_expected.to eq(key: 'null') }
      end # with nil value

      context 'with nested hash value' do
        let(:hash) { { key: { integer: 1234 } } }
        it { is_expected.to eq(key: { integer: '1234' }) }
      end # with nested hash value
    end # ::stringify_vals

    describe '::encode_www_data' do
      subject { Utils.encode_www_data(data) }

      context 'with empty hash' do
        let(:data) { {} }
        it { is_expected.to eq '' }
      end

      context 'with nil data' do
        let(:data) { nil }
        it { is_expected.to be nil }
      end

      context 'with flat data' do
        let(:data) { { a: '1', b: 2, c: 3.3 } }
        it { is_expected.to eq 'a=1&b=2&c=3.3' }
      end

      context 'with nested array' do
        let(:array) { [1,2,3] }
        let(:data) { { array: array } }
        it { is_expected.to eq 'array[]=1&array[]=2&array[]=3' }
      end

      context 'with nested hash' do
        let(:hash) { { a: 'a', b: 'b', c: 'c' } }
        let(:data) { { hash: hash } }
        it { is_expected.to eq 'hash[a]=a&hash[b]=b&hash[c]=c' }
      end
    end # ::encode_www_data
  end # Utils
end # Rester
