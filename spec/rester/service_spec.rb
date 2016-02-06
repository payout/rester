require 'support/test_service'

module Rester
  RSpec.describe Service do
    let(:service) do
      Class.new(Service).tap { |klass|
        allow(klass).to receive(:name) { 'Service' }
      }
    end

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

        # Setup mock middleware
        # Need to do this since we're mocking the ::new method.
        before {
          service_inst = nil

          allow(middleware_class).to receive(:new) { |a|
            service_inst = a
            middleware_class
          }

          allow(middleware_class).to receive(:app) { service_inst }
        }

        after {
          subject
          service.call({})
        }

        context 'with middleware but no arguments' do
          let(:args) { [] }

          it 'should call constructor with service instance' do
            expect(middleware_class).to receive(:new).with(service.instance)
              .once
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

      context 'with GET from mounted search endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/tests/1234/mounted_resources' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from search endpoint' do
          expect(response_body). to eq '{"resource":"mounted",'\
            '"method":"search","params":{"test_id":"1234"}}'
        end
      end

      context 'with POST to mounted create endpoint' do
        let(:verb) { 'POST' }
        let(:path) { '/v1/tests/1234/mounted_resources' }

        it 'should return a 201' do
          expect(response_code).to eq 201
        end

        it 'should respond from create endpoint' do
          expect(response_body). to eq '{"resource":"mounted",'\
            '"method":"create","params":{"test_id":"1234"}}'
        end
      end

      context 'with GET from mounted get endpoint' do
        let(:verb) { 'GET' }
        let(:path) { '/v1/tests/1234/mounted_resources/resource_id' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from get endpoint' do
          expect(response_body). to eq '{"resource":"mounted",'\
            '"method":"get","params":{"test_id":"1234",'\
            '"mounted_resource_id":"resource_id"}}'
        end
      end

      context 'with PUT to mounted update endpoint' do
        let(:verb) { 'PUT' }
        let(:path) { '/v1/tests/1234/mounted_resources/resource_id' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"resource":"mounted",'\
            '"method":"update","params":{"test_id":"1234",'\
            '"mounted_resource_id":"resource_id"}}'
        end
      end

      context 'with DELETE to mounted delete endpoint' do
        let(:verb) { 'DELETE' }
        let(:path) { '/v1/tests/1234/mounted_resources/resource_id' }

        it 'should return a 200' do
          expect(response_code).to eq 200
        end

        it 'should respond from update endpoint' do
          expect(response_body). to eq '{"resource":"mounted",'\
            '"method":"delete","params":{"test_id":"1234",'\
            '"mounted_resource_id":"resource_id"}}'
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

    describe '::service_name' do
      subject { service.service_name }

      context 'with named service class' do
        let(:service) { Rester::DummyService }
        it { is_expected.to eq "DummyService" }
      end

      context 'with anonymous service class' do
        let(:service) { Class.new(Service) }
        it { is_expected.to eq 'Anonymous' }
      end
    end # ::service_name

    describe '#name' do
      let(:service) { Rester::DummyService }
      subject { service.instance.name }

      it { is_expected.to eq "DummyService" }
    end # #name

    describe '#logger' do
      subject { service.logger }
      it { is_expected.to eq Rester.logger }
    end # #logger

    describe '#logger=' do
      let(:new_logger) { double('logger') }
      before { service.logger = new_logger }
      subject { service.logger }
      it 'should set the new logger' do
        expect(subject.logger).to eq new_logger
      end
    end # #logger=
  end # Service
end # Rester
