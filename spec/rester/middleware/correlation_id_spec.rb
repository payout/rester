module Rester
  module Middleware
    RSpec.describe CorrelationId do
      let(:service) { TestService.new }

      describe '#call' do
      end # #call

      describe '#identify_method' do
        subject { instance.identify_method(request) }
        let(:request) { Service::Request.new(env) }
        let(:id) { SecureRandom.uuid }
        let(:env) {
          {
            'REQUEST_METHOD' => verb,
            'PATH_INFO' => path,
            'X-Rester-Correlation-ID' => id
          }
        }
      end # #identify_method
    end # Correlation_id
  end # Middleware
end # Rester
