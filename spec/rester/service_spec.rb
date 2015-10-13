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
      subject { service.call(env: 'goes here') }

      context 'with validation error' do
        before {
          allow(service.instance).to receive(:call) {
            Errors.throw_error!(Errors::ValidationError)
          }
        }

        it 'should return a 400 error' do
          expect(subject.first).to eq 400
        end
      end
    end # ::call
  end # Service
end # Rester
