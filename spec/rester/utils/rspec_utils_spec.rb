module Rester
  module Utils
    RSpec.describe RSpec do
      describe '#deep_include?' do
        subject { Rester::Utils::RSpec.deep_include?(subj, stub) }
        let(:subj) {}
        let(:stub) {}

        context 'with failures' do
          context 'with missing Hash' do
            let(:subj) {{ this: :that }}
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value
                }
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash]={:some_key=>:some_value} doesn't match Subject[:some_hash]=nil"
            end
          end # with missing Hash

          context 'with missing Array' do
            let(:subj) {{ this: :that }}
            let(:stub) {
              {
                this: :that,
                some_array: [1, 2, 3]
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array]=[1, 2, 3] doesn't match Subject[:some_array]=nil"
            end
          end # with missing Array

          context 'with missing Array in Hash' do
            let(:subj) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value
                }
              }
            }
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  some_array: [1, 2, 3]
                }
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash][:some_array]=[1, 2, 3] doesn't match Subject[:some_hash][:some_array]=nil"
            end
          end # with missing Array in Hash

          context 'with missing hash key' do
            let(:subj) {
              {
                this: :that,
                some_hash: {
                  a_different_key: :some_value
                }
              }
            }
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value
                }
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash][:some_key]=:some_value doesn't match Subject[:some_hash][:some_key]=nil"
            end
          end # with missing hash key

          context 'with missing array element' do
            let(:subj) {
              {
                this: :that,
                some_array: [1, 2]
              }
            }
            let(:stub) {
              {
                this: :that,
                some_array: [1, 2, 3]
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array][2]=3 doesn't match Subject[:some_array][2]=nil"
            end
          end # with missing array element

          context 'with different hash value' do
            let(:subj) {
              {
                this: :that,
                some_hash: {
                  some_key: :a_different_value
                }
              }
            }
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value
                }
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_hash][:some_key]=:some_value doesn't match Subject[:some_hash][:some_key]=:a_different_value"
            end
          end # with different hash value

          context 'with different array element' do
            let(:subj) {
              {
                this: :that,
                some_array: [1, 2, 4]
              }
            }
            let(:stub) {
              {
                this: :that,
                some_array: [1, 2, 3]
              }
            }

            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError, "Stub[:some_array][2]=3 doesn't match Subject[:some_array][2]=4"
            end
          end # with different array element
        end # with failures

        context 'with successes' do
          context 'with simple hash' do
            let(:subj) {
              {
                integer: 1,
                float: 1.23,
                string: 'hello',
                symbol: :hello,
                boolean: true,
                another_boolean: false,
                extra_string: 'extra',
                extra_symbol: :extra
              }
            }
            let(:stub) {
              {
                integer: 1,
                float: 1.23,
                string: 'hello',
                symbol: :hello,
                boolean: true,
                another_boolean: false
              }
            }

            it { is_expected.to be true }
          end # with simple hash

          context 'with nested hash' do
            let(:subj) {
              {
                this: :that,
                some_hash: {
                  integer: 1,
                  float: 1.23,
                  string: 'hello',
                  symbol: :hello,
                  boolean: true,
                  another_boolean: false,
                  extra_string: 'extra',
                  extra_symbol: :extra
                }
              }
            }
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  integer: 1,
                  float: 1.23,
                  string: 'hello',
                  symbol: :hello,
                  boolean: true,
                  another_boolean: false,
                  extra_string: 'extra',
                  extra_symbol: :extra
                }
              }
            }

            it { is_expected.to be true }
          end # with nested hash

          context 'with nested array' do
            let(:subj) {
              {
                this: :that,
                some_array: [1, 2, 3],
                extra_field: 1
              }
            }
            let(:stub) {
              {
                this: :that,
                some_array: [1, 2, 3]
              }
            }

            it { is_expected.to be true }
          end # with nested array

          context 'with array in a nested hash' do
            let(:subj) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value,
                  some_array: [1, 2, 3]
                },
                extra_field: 1
              }
            }
            let(:stub) {
              {
                this: :that,
                some_hash: {
                  some_key: :some_value,
                  some_array: [1, 2, 3]
                }
              }
            }

            it { is_expected.to be true }
          end # with array in a nested hash

          context 'with hash in a nested array' do
            let(:subj) {
              {
                this: :that,
                some_array: [1, 2, { hello: :world }],
                extra_field: 1
              }
            }
            let(:stub) {
              {
                this: :that,
                some_array: [1, 2, { hello: :world }]
              }
            }

            it { is_expected.to be true }
          end # wtih hash in a nested array
        end # with successes
      end # #deep_include?
    end # RSpec
  end # Utils
end # Rester