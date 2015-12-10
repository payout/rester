module Rester
  RSpec.describe Utils do
    describe '::stringify' do
      subject { Utils.stringify(hash) }

      context 'with empty hash' do
        let(:hash) { {} }
        it { is_expected.to eq({}) }
      end # with empty hash

      context 'with string value' do
        let(:hash) { { key: 'value' } }
        it { is_expected.to eq('key' => 'value') }
      end # with string value

      context 'with symbol value' do
        let(:hash) { { key: :value } }
        it { is_expected.to eq('key' => 'value') }
      end # with symbol value

      context 'with float value' do
        let(:hash) { { key: 3.14159 } }
        it { is_expected.to eq('key' => '3.14159') }
      end # with float value

      context 'with integer value' do
        let(:hash) { { key: 1234 } }
        it { is_expected.to eq('key' => '1234') }
      end # with integer value

      context 'with nil value' do
        let(:hash) { { key: nil } }
        it { is_expected.to eq('key' => nil) }
      end # with nil value

      context 'with nested hash value' do
        let(:hash) { { key: { integer: 1234 } } }
        it { is_expected.to eq('key' => { 'integer' => '1234' }) }
      end # with nested hash value
    end # ::stringify

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

      context 'with integer datum' do
        let(:data) { { a: 1 } }
        it { is_expected.to eq 'a=1' }
      end

      context 'with integer data' do
        let(:data) { { a: 1, b: 2, c: 3 } }
        it { is_expected.to eq 'a=1&b=2&c=3' }
      end

      context 'with string datum' do
        let(:data) { { a: 'aaa' } }
        it { is_expected.to eq 'a=aaa' }
      end

      context 'with string data' do
        let(:data) { { a: 'aaa', b: 'bbb', c: 'ccc' } }
        it { is_expected.to eq 'a=aaa&b=bbb&c=ccc' }
      end

      context 'with float datum' do
        let(:data) { { a: 1.1 } }
        it { is_expected.to eq 'a=1.1' }
      end

      context 'with float data' do
        let(:data) { { a: 1.1, b: 2.22, c: 3.333 } }
        it { is_expected.to eq 'a=1.1&b=2.22&c=3.333' }
      end

      context 'with symbol datum' do
        let(:data) { { a: :one } }
        it { is_expected.to eq 'a=one' }
      end

      context 'with symbol data' do
        let(:data) { { a: :one, b: :two, c: :three } }
        it { is_expected.to eq 'a=one&b=two&c=three' }
      end

      context 'with nil datum' do
        let(:data) { { a: nil } }
        it { is_expected.to eq 'a' }
      end

      context 'with nil data' do
        let(:data) { { a: nil, b: nil, c: nil } }
        it { is_expected.to eq 'a&b&c' }
      end

      context 'with empty array data' do
        let(:data) { { a: [] } }
        it { is_expected.to eq '' }
      end

      context 'with non-empty array data' do
        let(:data) { { a: ['one', 2, 3.3] } }
        it { is_expected.to eq 'a[]=one&a[]=2&a[]=3.3' }
      end

      context 'with non-empty array param containing a nil' do
        let(:data) { { a: ['one', nil, 3.3] } }
        it { is_expected.to eq 'a[]=one&a[]&a[]=3.3' }
      end

      context 'with two non-empty array data' do
        let(:data) { { a: ['one', 2, 3.3], b: [1, 2.2] } }
        it { is_expected.to eq 'a[]=one&a[]=2&a[]=3.3&b[]=1&b[]=2.2' }
      end

      context 'with nested empty array data' do
        let(:data) { { a: [[]] } }
        it { is_expected.to eq '' }
      end

      context 'with nested non-empty array data' do
        let(:data) { { a: [[1], [1,2], [1,2,3]] } }
        it { is_expected.to eq 'a[][]=1&a[][]=1&a[][]=2&a[][]=1&a[][]=2&'\
          'a[][]=3' }
      end

      context 'with array with nested hashes data' do
        let(:data) do
          { a: [{one: 1}, {one: 1, two: 2}, {one: 1, two: 2, three: 3}] }
        end

        it { is_expected.to eq 'a[][one]=1&a[][one]=1&a[][two]=2&a[][one]=1&'\
          'a[][two]=2&a[][three]=3' }
      end

      context 'with empty hash data' do
        let(:data) { { a: {} } }
        it { is_expected.to eq '' }
      end

      context 'with non-empty hash data' do
        let(:data) { { a: { a: 1, b: 2.2, c: 'three', ary: [1,2]} } }
        it { is_expected.to eq 'a[a]=1&a[b]=2.2&a[c]=three&a[ary][]=1&'\
          'a[ary][]=2' }
      end

      context 'with nested hash data' do
        let(:data) { { a: { hash: { one: 1, two: 2 } } } }
        it { is_expected.to eq 'a[hash][one]=1&a[hash][two]=2' }
      end
    end # ::encode_www_data
  end # Utils
end # Rester
