module Rester
  RSpec.describe Client do
    ##
    # Converts a hash into a hash that would be returned by the client.
    # Essentially, this is mostly to convert symbol values into strings.
    def json_h(params)
      JSON.parse(params.to_json, symbolize_names: true)
    end

    let(:adapter) { Client::Adapters::HttpAdapter.new }
    let(:client) { Client.new(adapter, version: version) }
    let(:version) { 1 }
    let(:test_url) { "#{RSpec.server_uri}" }

    # Request Hash
    let(:req_hash) { {string: "string", integer: 1, float: 1.1, symbol: :symbol, bool: true, null: nil} }

    # Response Hash
    let(:res_hash) { req_hash.map{|k,v| [k, v.nil? ? nil : v.to_s]}.to_h }

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
    end # #connected?

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

        context 'with unsupported version' do
          let(:version) { 2 }
          let(:args) { ['token'] }

          it 'should be unsuccessful' do
            expect(subject.get.successful?).to be false
          end

          it 'should have an error message' do
            expect(subject.get[:error]).to eq Errors::NotFoundError
            expect(subject.get[:message]).to eq '/v2/tests/token'
          end
        end # with unsupported version

        context 'with supported version' do
          context 'with string argument' do
            let(:args) { ['token'] }

            it { is_expected.to be_a Rester::Client::Resource }

            describe '#get' do
              let(:params) { {} }
              let(:expected_resp) { {token: 'token', params: json_h(params), method: 'get'} }

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

                  it 'should be successful' do
                    expect(subject.successful?).to be true
                  end

                  it { is_expected.to eq(expected_resp) }
                end

                context 'with triggered error!' do
                  let(:params) { {string: 'testing_error'} }

                  it 'should be unsuccessful' do
                    expect(subject.successful?).to be false
                  end

                  it 'should have an error message' do
                    expect(subject[:error]).to eq Errors::RequestError
                    expect(subject[:message]).to eq 'Rester::Errors::RequestError'
                  end

                  context 'with message' do
                    let(:params) { {string: 'testing_error_with_message'} }

                    it 'should have an error message' do
                      expect(subject[:error]).to eq Errors::RequestError
                      expect(subject[:message]).to eq 'testing_error_with_message'
                    end
                  end
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
                  params: json_h(params.merge(test_token: 'token'))
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
              let(:expected_resp) { {token: 'token', params: json_h(params), method: 'delete'} }

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

            describe '#mounted_objects' do
              let(:mounted_objects) { tests.mounted_objects(*margs) }

              context 'with mounted object token' do
                let(:margs) { ['mounted_id'] }

                describe '#update' do
                  let(:params) { req_hash }
                  subject { mounted_objects.update(params) }
                  it { is_expected.to eq res_hash.merge(test_token: 'token', mounted_object_id: 'mounted_id') }
                end # #update

                describe '#delete' do
                  subject { mounted_objects.delete }
                  it { is_expected.to eq(no: 'params accepted') }
                end # #delete

                # Multi-level
                describe '#mounted_objects' do
                  subject { mounted_objects.mounted_objects('mounted_id2').get }
                  it { is_expected.to eq(test_token: 'token', mounted_object_id: 'mounted_id2') }
                end
              end # with mounted object token
            end # mounted_object

            describe '#mounted_objects!' do
              let(:mounted_objects!) { tests.mounted_objects!(arg: 'required') }
              subject { mounted_objects! }

              it 'should be unsuccessful' do
                expect(subject.successful?).to be false
              end

              it 'should have an error message' do
                expect(subject[:error]).to eq Errors::NotFoundError
                expect(subject[:message]).to eq '/v1/tests/token/mounted_objects'
              end
            end # mounted_objects!
          end # with string argument

          context 'with hash argument' do
            let(:args) { [req_hash] }
            it { is_expected.to eq json_h(req_hash).merge(method: 'search') }
          end # with hash argument

          context 'with no arguments' do
            let(:args) { [] }
            it { is_expected.to eq(method: 'search') }
          end # with no arguments
        end # with supported version
      end # with connection
    end # #tests

    describe '#tests!', :tests! do
      let(:tests!) { client.tests!(*args) }
      subject { tests! }

      context 'without connection' do
        context 'with no arguments' do
          let(:args) { [] }
          it { expect { subject }.to raise_error RuntimeError, 'not connected' }
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
          it { is_expected.to eq(method: 'create') }
        end

        context 'with hash argument' do
          let(:args) { [req_hash] }
          it { is_expected.to eq json_h(req_hash).merge(method: 'create') }
        end # with hash argument
      end # with connection
    end # #tests!

    describe '#with_context' do
      let(:stub_file_path) { 'spec/stubs/dummy_stub.yml' }
      let(:context) { 'some_context' }

      context 'with StubAdapter' do
        let(:client) { Client.new(Client::Adapters::StubAdapter.new(stub_file_path)) }

        it 'should set the context of the adapter' do
          client.with_context(context) do
            expect(client.adapter.context).to eq context
          end
        end

        it 'should return the context back to nil' do
          client.with_context(context) {}
          expect(client.adapter.context).to eq nil
        end
      end # with StubAdapter
    end # #with_context
  end # Client
end # Rester
