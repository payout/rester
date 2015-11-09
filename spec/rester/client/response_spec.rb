module Rester
  class Client
    RSpec.describe Response do
      let(:response) { Response.new(status) }
      let(:status) { 200 }
      subject { response }

      it { is_expected.to be_a Hash }

      describe '#successful?' do
        subject { response.successful? }
        it { is_expected.to be true }

        context '299 error' do
          let(:status) { 299 }
          it { is_expected.to be true }
        end

        context '400 error' do
          let(:status) { 400 }
          it { is_expected.to be false }
        end

        context '404 error' do
          let(:status) { 404 }
          it { is_expected.to be false }
        end

        context '500 error' do
          let(:status) { 500 }
          it { is_expected.to be false }
        end
      end # #successful?
    end # Response
  end # Client
end # Rester