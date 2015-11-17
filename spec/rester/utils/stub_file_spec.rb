module Rester
  module Utils
    RSpec.describe StubFile do
      describe '::parse!' do
        let(:path) { '/v1/this/is/a/path' }
        let(:verb) { 'GET' }
        let(:context) { 'This is a context'}
        let(:response_key) { 'response' }
        let(:response_data) { {} }

        let(:stub_hash) do
          {
            path => {
              verb => {
                context => {
                  response_key => response_data
                }
              }
            }
          }
        end

        subject { StubFile.parse!(stub_hash) }
        let(:parsed_context) { subject[path][verb][context] }

        context 'with missing response' do
          let(:response_key) { nil }

          it 'should raise error' do
            expect { subject }.to raise_error(
              Errors::StubError,
              "GET #{path} is missing a response for the "\
              "context #{context.inspect}"
            )
          end
        end # with missing response

        context 'with multiple responses' do
          before do
            stub_hash[path][verb][context].merge!(
              'response[successful=true]' => {},
              'response[successful=false]' => {}
            )
          end

          it 'should raise error' do
            expect { subject }.to raise_error(
              Errors::StubError,
              "GET #{path} has too many responses defined for "\
              "the context #{context.inspect}"
            )
          end
        end # with multiple responses

        context 'with response with no tags' do
          let(:response_key) { 'response' }
          let(:response_data) { { 'hello' => 'world' } }

          it 'should preserve response' do
            expect(parsed_context['response']).to eq response_data
          end

          it 'should have response code of 200' do
            expect(parsed_context['response_code']).to eq 200
          end

          it 'should have default tags' do
            expect(parsed_context['response_tags']).to eq StubFile::DEFAULT_TAGS
          end
        end # with response with no tags

        context 'with response with successful=true and verb GET' do
          let(:response_key) { 'response[successful=true]' }
          let(:response_data) { { 'hello' => 'world' } }
          let(:verb) { 'GET' }

          it 'should create response key' do
            expect(parsed_context['response']).to eq response_data
          end

          it 'should have response code of 200' do
            expect(parsed_context['response_code']).to eq 200
          end

          it 'should make tags available' do
            expect(parsed_context['response_tags']).to eq(
              'successful' => 'true'
            )
          end
        end # with response with successful=true and verb GET

        context 'with response with successful=false and verb GET' do
          let(:response_key) { 'response[successful=false]' }
          let(:response_data) { { 'hello' => 'world' } }
          let(:verb) { 'GET' }

          it 'should have response code of 400' do
            expect(parsed_context['response_code']).to eq 400
          end
        end # with response with successful=false and verb GET

        context 'with response with successful=true and verb POST' do
          let(:response_key) { 'response[successful=true]' }
          let(:response_data) { { 'hello' => 'world' } }
          let(:verb) { 'POST' }

          it 'should have response code of 201' do
            expect(parsed_context['response_code']).to eq 201
          end
        end # with response with successful=true and verb POST

        context 'with response with successful=false and verb POST' do
          let(:response_key) { 'response[successful=false]' }
          let(:response_data) { { 'hello' => 'world' } }
          let(:verb) { 'POST' }

          it 'should have response code of 400' do
            expect(parsed_context['response_code']).to eq 400
          end
        end # with response with successful=false and verb POST

        context 'with multiple response tags' do
          let(:response_key) { 'response[key=value, a = b,face=  palm]' }

          it 'should make tags available' do
            expect(parsed_context['response_tags']).to eq(
              StubFile::DEFAULT_TAGS.merge(
                'key'  => 'value',
                'a'    => 'b',
                'face' => 'palm'
              )
            )
          end
        end # with multiple response tags
      end # ::parse!
    end # StubFile
  end # Utils
end # Rester
