module Rester
  RSpec.describe Client do
    let(:client) { Client.new }
    let(:test_url) { RSpec.server_uri }

    # Request Hash
    let(:req_hash) { {string: "string", integer: 1, float: 1.1, symbol: :symbol} }

    # Response Hash
    let(:res_hash) { req_hash.map{|k,v| [k, v.to_s]}.to_h }

    describe '#connect', :connect do
      subject { client.connect(url) }

      context 'with valid url' do
        let(:url) { test_url }

        it 'should return nil' do
          expect(subject).to be nil
        end
      end # valid url
    end # #connect

    describe '#connected?', :connected? do
      subject { client.connected? }

      context 'before connecting' do
        it { is_expected.to be false }
      end

      context 'after connecting' do
        before { client.connect(test_url) }
        it { is_expected.to be true }
      end
    end # #connect?

    describe '#tests', :tests do
      let(:tests) { client.tests(*args) }
      subject { tests }

      context 'without connection' do
        context 'with string argument' do
          let(:args) { ['token'] }

          describe '#get' do
            subject { tests.get }
            it { expect { subject }.to raise_error RuntimeError, 'not connected' }
          end

          describe '#update' do
            subject { tests.update }
            it { expect { subject }.to raise_error RuntimeError, 'not connected' }
          end

          describe '#delete' do
            subject { tests.delete }
            it { expect { subject }.to raise_error RuntimeError, 'not connected' }
          end
        end # with string argument

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { expect { subject }.to raise_error RuntimeError, 'not connected' }
        end # with hash argument
      end # without connection

      context 'with connection' do
        before { client.connect(test_url) }

        context 'with string argument' do
          let(:args) { ['token'] }

          it { is_expected.to be_a Rester::Client::Resource }

          describe '#get' do
            let(:params) { {} }
            let(:expected_resp) { {token: 'token', params: params.map{|k,v| [k, v.to_s]}.to_h, method: 'get'} }

            context 'without argument' do
              subject { tests.get }
              it { is_expected.to eq(expected_resp) }
            end # without argument

            context 'with argument' do
              let(:params) { {} }
              subject { tests.get(params) }
              it { is_expected.to eq(expected_resp) }

              context 'with params' do
                let(:params) { req_hash }
                it { is_expected.to eq(expected_resp) }
              end

              context 'with nil argument' do
                let(:params) { nil }
                it { is_expected.to eq(token: 'token', params: {}, method: 'get') }
              end
            end # with argument
          end # #get

          describe '#update' do
            let(:params) { {} }
            let(:expected_resp) {
              {
                method: 'update',
                int: 1, float: 1.1, bool: true, null: nil,
                params: params.map{|k,v| [k, v.to_s]}.to_h
              }
            }

            context 'without argument' do
              subject { tests.update }
              it { is_expected.to eq expected_resp }
            end # without argument

            context 'with argument' do
              subject { tests.update(params) }

              context 'with empty params' do
                let(:params) { {} }
                it { is_expected.to eq expected_resp }
              end

              context 'with params' do
                let(:params) { req_hash }
                it { is_expected.to eq expected_resp }
              end
            end # with argument
          end # #update

          describe '#delete' do
            let(:params) { {} }
            let(:expected_resp) { {token: 'token', params: params.map{|k,v| [k, v.to_s]}.to_h, method: 'delete'} }

            context 'without argument' do
              subject { tests.delete }
              it { is_expected.to eq(expected_resp) }
            end # without argument

            context 'with argument' do
              let(:params) { {} }
              subject { tests.delete(params) }

              before { client.connect(test_url) }
              it { is_expected.to eq expected_resp }

              context 'with params' do
                let(:params) { req_hash }
                it { is_expected.to eq expected_resp }
              end
            end # with argument
          end # #delete

          describe '#mounted_object' do
            let(:mounted_object) { tests.mounted_object(*margs) }

            context 'with mounted object token' do
              let(:margs) { ['mounted_id'] }

              describe '#update' do
                let(:params) { req_hash }
                subject { mounted_object.update(params) }
                it { is_expected.to eq res_hash.merge(test_token: 'token') }
              end # #update

              describe '#delete' do
                subject { mounted_object.delete }
                it { is_expected.to eq(no: 'params accepted') }
              end # #delete

              # Multi-level
              describe '#mounted_object' do
                subject { mounted_object.mounted_object('mounted_id2').get }
                it { is_expected.to eq(test_token: 'token', mounted_object_id: 'mounted_id', id: 'mounted_id2') }
              end
            end # with mounted object token
          end # mounted_object
        end # with string argument

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { is_expected.to eq res_hash.merge(method: 'search') }
        end # with hash argument

        context 'with no arguments' do
          let(:args) { [] }
          it { expect { subject }.to raise_error ArgumentError, 'wrong number of arguments (0 for 1)' }
        end # with no arguments
      end # with connection
    end # #tests

    describe '#tests!', :tests! do
      let(:tests!) { client.tests!(*args) }
      subject { tests! }

      context 'without connection' do
        context 'with no arguments' do
          let(:args) { [] }
          it { expect { subject }.to raise_error ArgumentError, 'wrong number of arguments (0 for 1)' }
        end

        context 'with hash argument' do
          let(:args) { [{}] }
          it { expect { subject }.to raise_error RuntimeError, 'not connected' }
        end
      end # without connection

      context 'with connection' do
        before { client.connect(test_url) }

        context 'with no arguments' do
          let(:args) { [] }
          it { expect { subject }.to raise_error ArgumentError, 'wrong number of arguments (0 for 1)' }
        end

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { is_expected.to eq res_hash.merge(method: 'create') }
        end # with hash argument
      end # with connection
    end # #tests!
  end # Client
end # Rester
