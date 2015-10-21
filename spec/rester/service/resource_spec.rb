require 'date'

module Rester
  class Service
    RSpec.describe Resource do
      let(:object) { Class.new(Resource) }

      describe '::params' do
        before do
          object.params strict: true, an_option: 'value' do
            Integer  :one, between?: [1, 10], required: true
            String   :two, match: /hello world/, required: true
            Symbol   :three, within: [:a, :b, :c], required: false
            Float    :four
            DateTime :five
          end
        end

        it 'should have set options' do
          expect(object.validator.options).to eq(
            strict: true, an_option: 'value')
          expect(object.validator.strict?).to be true
        end
      end # ::params
    end # Resource
  end # Service
end # Rester
