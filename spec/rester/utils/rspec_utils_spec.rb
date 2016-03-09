module Rester
  module Utils
    RSpec.describe RSpec do
      describe '#assert_deep_include' do
        subject { Rester::Utils::RSpec.assert_deep_include(response, stub) }
        let(:response) {}
        let(:stub) {}
        let(:test_hash) {
          {
            integer: 1,
            float: 1.23,
            string: 'hello',
            symbol: :hello,
            boolean: true,
            another_boolean: false
          }
        }
        let(:test_hash_with_extra) {
          test_hash.merge(
            extra_string: 'extra',
            extra_symbol: :extra
          )
        }
        let(:test_array) { [1, 2, 3] }
        let(:test_array_with_extra) { test_array + [4] }

        context 'with failures' do
          context 'with missing Hash' do
            let(:response) { {} }
            let(:stub) {{ some_hash: test_hash }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash] type: Hash doesn't match Response[:some_hash] type: NilClass"
            end
          end

          context 'with missing Array' do
            let(:response) { {} }
            let(:stub) {{ some_array: test_array }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array] type: Array doesn't match Response[:some_array] type: NilClass"
            end
          end

          context 'with missing Array in nested Hash' do
            let(:response) {{ some_hash: {} }}
            let(:stub) {{ some_hash: { some_array: test_array } }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash][:some_array] type: Array doesn't match Response[:some_hash][:some_array] type: NilClass"
            end
          end

          context 'with missing keys in nested hash' do
            let(:response) {{ some_hash: test_hash }}
            let(:stub) {{ some_hash: test_hash_with_extra }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, 'Stub[:some_hash][:extra_string]="extra" doesn\'t match Response[:some_hash][:extra_string]=nil'
            end
          end

          context 'with missing array element' do
            let(:response) {{ some_array: test_array }}
            let(:stub) {{ some_array: test_array_with_extra }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array] length: 4 doesn't match Response[:some_array] length: 3"
            end
          end

          context 'with different array lengths' do
            let(:response) {{ some_array: test_array_with_extra }}
            let(:stub) {{ some_array: test_array }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array] length: 3 doesn't match Response[:some_array] length: 4"
            end
          end

          context 'with different hash value' do
            let(:response) {{ some_hash: test_hash }}
            let(:stub) {{ some_hash: test_hash.merge(string: 'different') }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, 'Stub[:some_hash][:string]="different" doesn\'t match Response[:some_hash][:string]="hello"'
            end
          end

          context 'with different array element' do
            let(:response) {{ some_array: test_array }}
            let(:stub) {{ some_array: test_array.dup.tap { |a| a[0] = 3 } }}

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array][0]=3 doesn't match Response[:some_array][0]=1"
            end
          end

          context 'with different regexp value' do
            let(:response) { test_hash }
            let(:stub) { test_hash.merge(string: /\Abad_matcher\z/) }
            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:string]=/\\Abad_matcher\\z/ doesn't match Response[:string]=\"hello\""
            end
          end
        end # with failures

        context 'with successes' do
          context 'with extra fields in response' do
            let(:response) { test_hash_with_extra }
            let(:stub) { test_hash }
            it { is_expected.to be true }
          end

          context 'with nested hash with extra fields in response' do
            let(:response) {{ some_hash: test_hash_with_extra }}
            let(:stub)  {{ some_hash: test_hash }}
            it { is_expected.to be true }
          end

          context 'with nested array' do
            let(:response) {{ some_array: test_array }}
            let(:stub) { response.dup }
            it { is_expected.to be true }
          end

          context 'with nested array with extra fields in response' do
            let(:response) {{ some_array: test_array }}
            let(:stub) { response.dup }
            it { is_expected.to be true }
          end

          context 'with array in a nested hash' do
            let(:response) {{ some_hash: { some_array: test_array } }}
            let(:stub) { response.dup }
            it { is_expected.to be true }
          end

          context 'with hash in a nested array' do
            let(:response) {{ some_array: [1, 2, { hello: :world }] }}
            let(:stub) { response.dup }
            it { is_expected.to be true }
          end

          context 'with matching regexp value' do
            let(:response) { test_hash }
            let(:stub) { test_hash.merge(string: /\Ahe.*\z/) }
            it { is_expected.to be true }
          end
        end # with successes
      end # #assert_deep_include
    end # RSpec
  end # Utils
end # Rester