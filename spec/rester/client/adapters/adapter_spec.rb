module Rester
  module Client::Adapters
    RSpec.describe Adapter do
      # TODO: Test that verbs, paths and params are passed to the subclass
      # as expected. Particularly, that params are encoded properly beforehand.

      let(:adapter_class) { Class.new(Adapter) }
      let(:adapter) { adapter_class.new(service, opts) }
      let(:service) { nil }
      let(:opts) { {} }

      describe '#timeout' do
        subject { adapter.timeout }

        context 'without the timeout option specified' do
          let(:opts) { {} }
          it { is_expected.to be nil }
        end

        context 'with the timeout option given as integer' do
          let(:opts) { { timeout: 1234 } }
          it { is_expected.to eq 1234 }
        end

        context 'with the timeout option given as float' do
          let(:opts) { { timeout: 3.14159 } }
          it { is_expected.to eq 3.14159 }
        end
      end # #timeout

      describe '#request' do
        subject { adapter.request(verb, path, params) }
        let(:verb) { :get }
        let(:path) { '/' }
        let(:params) { nil }

        context 'with GET "/" and no params' do
          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, nil).once
            subject
          end
        end

        context 'with integer params' do
          let(:params) { { a: 1, b: 2, c: 3 } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a=1&b=2&c=3').once
            subject
          end
        end

        context 'with string params' do
          let(:params) { { a: 'aaa', b: 'bbb', c: 'ccc' } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a=aaa&b=bbb&c=ccc').once
            subject
          end
        end

        context 'with float params' do
          let(:params) { { a: 1.1, b: 2.22, c: 3.333 } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a=1.1&b=2.22&c=3.333').once
            subject
          end
        end

        context 'with symbol params' do
          let(:params) { { a: :one, b: :two, c: :three } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a=one&b=two&c=three').once
            subject
          end
        end

        context 'with nil params' do
          let(:params) { { a: nil, b: nil, c: nil } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, 'a&b&c').once
            subject
          end
        end

        context 'with empty array param' do
          let(:params) { { a: [] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, '').once
            subject
          end
        end

        context 'with non-empty array param' do
          let(:params) { { a: ['one', 2, 3.3] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[]=one&a[]=2&a[]=3.3').once
            subject
          end
        end

        context 'with non-empty array param containing a nil' do
          let(:params) { { a: ['one', nil, 3.3] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[]=one&a[]&a[]=3.3').once
            subject
          end
        end

        context 'with two non-empty array params' do
          let(:params) { { a: ['one', 2, 3.3], b: [1, 2.2] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[]=one&a[]=2&a[]=3.3&b[]=1&b[]=2.2').once
            subject
          end
        end

        context 'with nested empty array param' do
          let(:params) { { a: [[]] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, '').once
            subject
          end
        end

        context 'with nested non-empty array param' do
          let(:params) { { a: [[1], [1,2], [1,2,3]] } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[][]=1&a[][]=1&a[][]=2&a[][]=1&a[][]=2&'\
                'a[][]=3').once
            subject
          end
        end

        context 'with array with nested hashes param' do
          let(:params) do
            { a: [{one: 1}, {one: 1, two: 2}, {one: 1, two: 2, three: 3}] }
          end

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[][one]=1&a[][one]=1&a[][two]=2&a[][one]=1&'\
                'a[][two]=2&a[][three]=3').once
            subject
          end
        end

        context 'with empty hash param' do
          let(:params) { { a: {} } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, '').once
            subject
          end
        end

        context 'with non-empty hash param' do
          let(:params) { { a: { a: 1, b: 2.2, c: 'three', ary: [1,2]} } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[a]=1&a[b]=2.2&a[c]=three&a[ary][]=1&'\
                'a[ary][]=2').once
            subject
          end
        end

        context 'with nested hash param' do
          let(:params) { { a: { hash: { one: 1, two: 2 } } } }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!)
              .with(verb, path, 'a[hash][one]=1&a[hash][two]=2').once
            subject
          end
        end

        context 'with POST "/tests" and no params' do
          let(:verb) { :post }
          let(:path) { '/tests' }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, nil).once
            subject
          end
        end

        context 'with PUT "/some/endpoint/here" and no params' do
          let(:verb) { :put }
          let(:path) { '/some/endpoint/here' }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, nil).once
            subject
          end
        end

        context 'with DELETE "some-other-resource" and no params' do
          let(:verb) { :put }
          let(:path) { 'some-other-resource' }

          it 'should call #request! with correct args' do
            expect(adapter).to receive(:request!).with(verb, path, nil).once
            subject
          end
        end

        context 'with OPTIONS "/path" and no params' do
          let(:verb) { :options }
          let(:path) { '/path' }

          it 'should call #request! with correct args' do
            expect { subject }.to raise_error ArgumentError,
              'Invalid verb: :options'
          end
        end
      end # #request
    end # Adapter
  end # Client::Adapters
end # Rester
