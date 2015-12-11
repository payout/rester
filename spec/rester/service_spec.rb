require 'support/test_service'

module Rester
  RSpec.describe Service do
    let(:service) { Class.new(Service) }

    describe '::use' do
      subject { service.use(*middleware) }

      context 'with no middleware' do
        let(:middleware) { [] }

        it 'should raise error' do
          expect { subject }.to raise_error ArgumentError, 'wrong number of arguments (0 for 1+)'
        end
      end # with no middleware

      context 'when service called' do
        let(:middleware_class) { double('middleware') }
        let(:middleware) { [middleware_class, *args] }

        after {
          subject
          service.call({})
        }

        context 'with middleware but no arguments' do
          let(:args) { [] }

          it 'should call constructor with service instance' do
            expect(middleware_class).to receive(:new).with(service.instance).once
          end
        end # with middleware but no arguments

        context 'with middleware and arguments' do
          let(:args) { [1, :two, 'three', 4.0] }

          it 'should call constructor with service instance' do
            expect(middleware_class).to receive(:new).with(
              service.instance,
              *args
            ).once
          end
        end # with middleware and arguments
      end # when service called
    end # ::use

    describe '::call' do
      let(:service) { TestService }
      subject { service.call(env) }

      let(:env) do
        {
          'REQUEST_METHOD' => verb,
          'PATH_INFO'      => path,
          'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
          'QUERY_STRING'   => query_string,
          'rack.input'     => StringIO.new(body)
        }
      end

      let(:verb) { 'GET' }
      let(:path) { '/v1/tests' }
      let(:query_string) { '' }
      let(:body) { '' }

      let(:response_code) { subject.first }
      let(:response_body) { subject.last.body.join }

      context 'with validation error' do
        # TODO: This seems like more of a test for the ErrorHandling middleware.
        before {
          allow(service.instance).to receive(:call) {
            Errors.throw_error!(Errors::ValidationError)
          }
        }

        it 'should return a 400 error' do
          expect(response_code).to eq 400
        end
      end

      context 'with GET from valid search endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/tests' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from search endpoint' do
          expect(response_body). to eq '{"method":"search","params":{}}'
        end
      end

      context 'with POST to valid create endpoint' do
        let(:verb) { 'POST' }
        let(:path) { '/v1/tests' }

        it 'should return a 201' do
          expect(response_code).to eq 201
        end

        it 'should respond from create endpoint' do
          expect(response_body). to eq '{"method":"create","params":{}}'
        end
      end

      context 'with GET from valid get endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/tests/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"method":"get","params":'\
            '{"test_id":"1234"}}'
        end
      end

      context 'with PUT to valid update endpoint' do
        let(:verb) { 'PUT' }
        let(:path) { '/v1/tests/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"method":"update","params":'\
            '{"test_id":"1234"}}'
        end
      end

      context 'with DELETE to valid delete endpoint' do
        let(:verb) { 'DELETE' }
        let(:path) { '/v1/tests/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from delete endpoint' do
          expect(response_body). to eq '{"method":"delete","params":'\
            '{"test_id":"1234"}}'
        end
      end

      context 'with GET from error causing search endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/errors' }

        it 'should return a 400' do
          expect(response_code).to eq 400
        end

        it 'should respond from search endpoint' do
          expect(response_body). to eq '{"error":"search","message":"{}"}'
        end
      end

      context 'with POST to error causing create endpoint' do
        let(:verb) { 'POST' }
        let(:path) { '/v1/errors' }

        it 'should return a 400' do
          expect(response_code).to eq 400
        end

        it 'should respond from create endpoint' do
          expect(response_body). to eq '{"error":"create","message":"{}"}'
        end
      end

      context 'with GET from error causing get endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/errors/1234' }

        it 'should return a 400' do
          expect(response_code).to eq 400
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"error":"get","message":'\
            '"{\"error_id\":\"1234\"}"}'
        end
      end

      context 'with PUT to error causing update endpoint' do
        let(:verb) { 'PUT' }
        let(:path) { '/v1/errors/1234' }

        it 'should return a 400' do
          expect(response_code).to eq 400
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"error":"update","message":'\
            '"{\"error_id\":\"1234\"}"}'
        end
      end

      context 'with DELETE to error causing delete endpoint' do
        let(:verb) { 'DELETE' }
        let(:path) { '/v1/errors/1234' }

        it 'should return a 400' do
          expect(response_code).to eq 400
        end

        it 'should respond from delete endpoint' do
          expect(response_body). to eq '{"error":"delete","message":'\
            '"{\"error_id\":\"1234\"}"}'
        end
      end

      context 'with GET from valid get endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/custom_id_names/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond with custom ID name' do
          expect(response_body). to eq '{"method":"get","params":'\
            '{"custom_id_name_custom":"1234"}}'
        end
      end

      context 'with PUT to valid update endpoint' do
        let(:verb) { 'PUT' }
        let(:path) { '/v1/custom_id_names/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond with custom ID name' do
          expect(response_body). to eq '{"method":"update","params":'\
            '{"custom_id_name_custom":"1234"}}'
        end
      end

      context 'with DELETE to valid delete endpoint' do
        let(:verb) { 'DELETE' }
        let(:path) { '/v1/custom_id_names/1234' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond with custom ID name' do
          expect(response_body). to eq '{"method":"delete","params":'\
            '{"custom_id_name_custom":"1234"}}'
        end
      end

      context 'with undefined resource' do
        before { service }
        let(:path) { '/v1/undefined_resource' }

        it 'should return a 404' do
          expect(response_code).to eq 404
        end
      end

      context 'with undefined version' do
        before { service }
        let(:path) { '/v10/tests' }

        it 'should return a 404' do
          expect(response_code).to eq 404
        end
      end
    end # ::call
  end # Service
end # Rester
