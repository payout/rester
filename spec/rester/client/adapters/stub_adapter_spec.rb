module Rester
  module Client::Adapters
    RSpec.describe StubAdapter do
      let(:stub_file_path) { 'spec/stubs/dummy_stub.yml' }
      let(:stub_adapter) { StubAdapter.new(stub_file_path, opts) }
      let(:opts) { {} }

      describe '::can_connect_to?' do
        subject { StubAdapter.can_connect_to?(service) }
        let(:service) { '' }

        context 'with non-string' do
          let(:service) { DummyService }
          it { is_expected.to be false }
        end # with non-string

        context 'with valid file path' do
          let(:service) { stub_file_path }
          it { is_expected.to be true }
        end # with valid file path

        context 'with invalid directory path' do
          let(:service) { 'spec/stubs' }
          it { is_expected.to be false }
        end # with invalid directory path
      end # ::can_connect_to?

      describe '#connected?' do
        subject { stub_adapter.connected? }
        it { is_expected.to eq true }
      end # #connected?

      describe 'request validation' do
        subject { request }
        let(:request) { stub_adapter.send("#{verb}!", path, params) }
        let(:verb) { 'get' }
        let(:path) { '/' }
        let(:context) { nil }
        let(:params) { {} }

        around { |ex| stub_adapter.with_context(context) { ex.run } }

        context 'with invalid path' do
          let(:path) { '/v1/invalid_path' }

          it 'should raise an error' do
            expect { subject }.to raise_error Errors::StubError, "#{path} not found"
          end
        end # with invalid path

        context 'with invalid verb' do
          let(:path) { '/v1/cards' }

          it 'should raise an error' do
            expect { subject }.to raise_error Errors::StubError, "GET #{path} not found"
          end
        end # with invalid verb

        context 'with invalid context' do
          let(:context) { 'an invalid context' }
          let(:path) { '/v1/cards/CTabcdef' }

          it 'should raise an error' do
            expect { subject }.to raise_error Errors::StubError,
              "GET /v1/cards/CTabcdef with context '#{context}' not found"
          end
        end # with invalid context

        context 'with invalid params' do
          let(:verb) { 'post' }
          let(:path) { '/v1/cards' }
          let(:context) { 'With valid card details' }

          it 'should raise an error' do
            expect { subject }.to raise_error Errors::StubError,
              'POST /v1/cards with context \'With valid card details\' params don\'t match stub: "card_number" should equal "4111111111111111" but got nil, "exp_month" should equal "08" but got nil, "exp_year" should equal "2017" but got nil'
          end
        end # with invalid params

        context 'with invalid and unexpected params' do
          let(:verb) { 'post' }
          let(:path) { '/v1/cards' }
          let(:context) { 'With valid card details' }
          let(:params) {{ unexpected_key: :some_value }}

          it 'should raise an error' do
            expect { subject }.to raise_error Errors::StubError,
              'POST /v1/cards with context \'With valid card details\' params don\'t match stub: "card_number" should equal "4111111111111111" but got nil, "exp_month" should equal "08" but got nil, "exp_year" should equal "2017" but got nil. Unexpected key(s): [:unexpected_key]'
          end
        end

        context 'without specifying context' do
          let(:verb) { 'post' }
          let(:path) { '/v1/cards' }

          context 'with matching params' do
            let(:params) {
              {
                'card_number' => "4111111111111111",
                'exp_month' => "08",
                'exp_year' => "2017"
              }
            }

            it 'should return a 201' do
              expect(subject.first).to eq 201
            end

            it 'should return json body' do
              expect(subject.last).to eq '{"token":"CTABCDEFG","exp_month":"08","exp_year":"2017","status":"ready"}'
            end
          end # matching params

          context 'without matching params' do
            it 'should raise an error' do
              expect { subject }.to raise_error Errors::StubError,
              "POST /v1/cards with context '#{context}' not found"
            end
          end # without matching params
        end # without specifying context
      end # request validation

      describe 'requests' do
        subject { stub_adapter.send("#{verb}!", path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last }
        let(:path) { '/' }
        let(:context) { nil }
        let(:params) { {} }

        around { |ex| stub_adapter.with_context(context) { ex.run } }

        describe '#get!' do
          let(:verb) { 'get' }

          context 'with path /v1/cards/CTabcdef' do
            let(:path) { '/v1/cards/CTabcdef' }

            context 'with card existing' do
              let(:context) { 'With card existing' }

              it 'should return 200 status' do
                expect(status).to eq 200
              end

              it 'should return json body' do
                expect(body).to eq '{"token":"CTabcdef","status":"ready"}'
              end
            end # with card existing

            context 'with non-existent card' do
              let(:context) { 'With non-existent card' }

              it 'should return 400 status' do
                expect(status).to eq 400
              end

              it 'should return json body' do
                expect(body).to eq '{"error":"validation_error","message":"card not found"}'
              end
            end # with non-existent card

            context 'with invalid params' do
              let(:params) {{ 'bad_field' => 'bad_field' }}
              let(:context) { 'With card existing' }

              it 'should raise an error' do
                expect { subject }.to raise_error Errors::StubError,
                  "GET /v1/cards/CTabcdef with context 'With card existing' params don't match stub: Unexpected key(s): [\"bad_field\"]"
              end
            end # with invalid params
          end # with path /v1/cards/CTabcdef
        end # #get!

        describe '#delete!' do
          let(:verb) { 'delete' }

          context 'with path /v1/cards/CTabcdef' do
            let(:path) { '/v1/cards/CTabcdef' }

            context 'with card existing' do
              let(:context) { 'With card existing' }

              it 'should return 200 status' do
                expect(status).to eq 200
              end

              it 'should return json body' do
                expect(body).to eq '{"token":"CTabcdef","status":"deleted"}'
              end
            end # with card existing
          end # with path /v1/cards/CTabcdef
        end # #delete!

        describe '#post!' do
          let(:verb) { 'post' }

          context 'with path /v1/cards' do
            let(:path) { '/v1/cards' }

            context 'with valid card details' do
              let(:context) { 'With valid card details' }
              let(:params) { {
                'card_number' => "4111111111111111",
                'exp_month' => "08",
                'exp_year' => "2017"
              }}

              it 'should return 201 status' do
                expect(status).to eq 201
              end

              it 'should return json body' do
                expect(body).to eq '{"token":"CTABCDEFG","exp_month":"08","exp_year":"2017","status":"ready"}'
              end
            end # with valid card details

            context 'with expired card' do
              let(:context) { 'With expired card' }
              let(:params) { {
                'card_number' => "411111111",
                'exp_month' => "01",
                'exp_year' => "2000"
              }}

              it 'should return 400 status' do
                expect(status).to eq 400
              end

              it 'should return json body' do
                expect(body).to eq '{"error":"validation_error","message":"card expired"}'
              end
            end # with expired card
          end # with path /v1/cards
        end # #post!

        describe '#put!' do
          let(:verb) { 'put' }

          context 'with path /v1/cards/CTabcdef/customers/CUabc123' do
            let(:path) { '/v1/cards/CTabcdef/customers/CUabc123' }

            context 'with valid customer' do
              let(:context) { 'Valid customer' }
              let(:params) { {
                'name' => "John Smith",
                'city' => "San Francisco",
                'state' => "CA"
              }}

              it 'should return 200 status' do
                expect(status).to eq 200
              end

              it 'should return json body' do
                expect(body).to eq '{"name":"John Smith","city":"San Francisco","state":"CA","status":"valid_customer"}'
              end
            end # with valid customer
          end # with path /v1/cards/CTabcdef/customers
        end # #put!
      end # requests
    end # StubAdapter
  end # Client::Adapters
end # Rester