module Rester
  module Client::Middleware
    RSpec.describe RequestHandler do
      let(:app) { double(:rack_app) }
      before {
        allow(app).to receive(:call) {
          expect(Rester.correlation_id).to match(/[\w]{8}(-[\w]{4}){3}-[\w]{12}/)
        }
      }

      subject { RequestHandler.new(app) }

      it 'should set up and clean up the correlation id' do
        expect(Rester.correlation_id).to eq nil
        subject.call({})
        expect(Rester.correlation_id).to eq nil
      end
    end # RequestHandler
  end # Client::Middleware
end # Rester