module Rester
  class Client
    RSpec.describe Adapters do
      include Adapters

      describe '::list' do
        subject { Adapters.list }

        it 'should return expected list' do
          is_expected.to eq(
            [
              Adapters::HttpAdapter,
              Adapters::LocalAdapter,
              Adapters::StubAdapter
            ]
          )
        end
      end # ::list
    end # Adapters
  end # Client::Adapters
end # Rester
