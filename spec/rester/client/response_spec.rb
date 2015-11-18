module Rester
  class Client
    RSpec.describe Response do
      let(:response) { Response.new(status, params) }
      let(:status) { 200 }
      let(:params) { {} }

      describe '#to_h' do
        subject { response.to_h }
        it { is_expected.to be_a Hash }
      end # #to_h

      describe '#initalize' do
        def frozen?(object)
          expect(object.frozen?).to be true if object.respond_to?(:frozen?)

          case object
          when Hash
            object.values.each { |v| frozen?(v) }
          when Array
            object.each { |v| frozen?(v) }
          end
        end

        let(:response) { Response.new(status, body) }
        let(:body) {
          {
            integer: 1,
            string: 'hello',
            symbol: :hello,
            array: [1, 'hello', [:this, 'that'], { here: 'there'}],
            hash: {
              hello: 'world',
              sizes: ['small', 'medium', 'large'],
              another: {
                here: 'there'
              }
            }
          }
        }

        it 'should be deep frozen' do
          frozen?(response)
        end
      end # #initialize

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

      describe '#==' do
        subject { response == other_hash }
        let(:params) { {} }
        let(:other_hash) { {} }

        context 'with equal hashes' do
          let(:params) { { some_key: 'some_value' } }
          it { is_expected.to be false }
        end # with equal hashes

        context 'with unequal hashes' do
          let(:params) { { some_key: 'some_value' } }
          let(:other_hash) { { some_key: 'some_value' } }
          it { is_expected.to be true }
        end # with unequal hashes
      end  # #==

      describe 'respond_to_missing?' do
        subject { response.respond_to?(:fetch) }
        it { is_expected.to be true }
      end
    end # Response
  end # Client
end # Rester