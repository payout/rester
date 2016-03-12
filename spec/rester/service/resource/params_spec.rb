require 'date'

module Rester
  class Service::Resource
    RSpec.describe Params do
      let(:resource_params) { Params.new(params_opts) }
      let(:params_opts) { {} }

      describe '#Integer' do
        let(:opts) { {} }
        before { resource_params.Integer(field, opts) }
        let(:field) { :an_integer }
        subject { resource_params.validate(field => value) }

        context 'with between?(1,10)' do
          let(:opts) { { between?: [1, 10] } }

          context 'with value of "1"' do
            let(:value) { '1' }
            it { is_expected.to eq(field.to_sym => value.to_i) }
          end

          context 'with value of "0"' do
            let(:value) { '0' }
            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new(
                  "#{field} failed between?(1,10) validation"
                )
            end
          end
        end # with between?(1,10)

        context 'with value of "123"' do
          let(:value) { '123' }
          it { is_expected.to eq(field.to_sym => 123) }
        end

        context 'with value of "3.14"' do
          let(:value) { '3.14' }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new("#{field} does not match "\
                '/\A\d+\z/')
          end
        end
      end # #Integer

      describe '#String' do
        before { resource_params.String(field, opts) }
        let(:field) { :a_string }
        subject { resource_params.validate(field => value) }

        context 'with match(/\A\w+\z/)' do
          let(:opts) { { match: /\A\w+\z/ } }

          context 'with value of "testing"' do
            let(:value) { 'testing' }
            it { is_expected.to eq(field.to_sym => value) }
          end

          context 'with value of "!@#$"' do
            let(:value) { '!@#$' }
            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new("#{field} does not match /\\A\\w+\\z/")
            end
          end
        end # with match(/\A\w+\z/)
      end # #String

      describe '#Symbol' do
        before { resource_params.Symbol(field, opts) }
        let(:field) { :a_symbol }
        subject { resource_params.validate(field => value) }

        context 'with within [:one, :two]' do
          let(:opts) { { within: [:one, :two] } }

          context 'with value of "one"' do
            let(:value) { 'one' }
            it { is_expected.to eq(field.to_sym => value.to_sym) }
          end

          context 'with value of "three"' do
            let(:value) { 'three' }
            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new(
                  "#{field} not within [:one, :two]"
                )
            end
          end
        end # with within [:one, :two]
      end # #Symbol

      describe '#Float' do
        let(:opts) { {} }
        before { resource_params.Float(field, opts) }
        let(:field) { :a_float }
        subject { resource_params.validate(field => value) }

        context 'with zero?()' do
          let(:opts) { { zero?: [] } }

          context 'with value of "0.0"' do
            let(:value) { '0.0' }
            it { is_expected.to eq(field.to_sym => value.to_f) }
          end

          context 'with value of "0"' do
            let(:value) { '0' }
            it { is_expected.to eq(field.to_sym => value.to_f) }
          end

          context 'with value of "0.25"' do
            let(:value) { '0.25' }
            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new(
                  "#{field} failed zero?() validation"
                )
            end
          end
        end # with zero?()

        context 'with value of "123"' do
          let(:value) { '123' }
          it { is_expected.to eq(field.to_sym => 123) }
        end

        context 'with value of "3.14159"' do
          let(:value) { '3.14159' }
          it { is_expected.to eq(field.to_sym => 3.14159) }
        end

        context 'with value of "3."' do
          let(:value) { '3.' }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new("#{field} does not match "\
                '/\A\d+(\.\d+)?\z/')
          end
        end
      end # #Float

      describe '#Array', :Array do
        let(:opts) { {} }
        let(:block) { nil }
        before { resource_params.Array(field, opts, &block) }
        let(:field) { :an_array }
        subject { resource_params.validate(field => value) }

        context 'with nil array' do
          let(:value) { nil }
          it { is_expected.to eq(field => value) }
        end

        context 'with String instead of Array' do
          let(:value) { "some_string" }

          it 'should raise an error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new("expected an_array to be of type Array")
          end
        end

        context 'with nil array and required' do
          let(:opts) { { required: true } }
          let(:value) { nil }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('an_array cannot be null')
          end
        end

        context 'with array of strings' do
          let(:value) { ['1', 'two', '3.3'] }
          it { is_expected.to eq(field.to_sym => value) }
        end

        context 'with array of strings and type = Integer' do
          let(:opts) { { type: Integer } }
          let(:value) { ['1', '2', '3'] }
          it { is_expected.to eq(field.to_sym => [1,2,3]) }
        end

        context 'with array of strings and type = Float' do
          let(:opts) { { type: Float } }
          let(:value) { ['1', '2.0', '3.3'] }
          it { is_expected.to eq(field.to_sym => [1.0,2.0,3.3]) }
        end

        context 'with array of strings and required' do
          let(:opts) { { required: true } }
          let(:value) { ['one', 'two', 'three'] }
          it { is_expected.to eq(field.to_sym => ['one', 'two', 'three']) }
        end

        context 'with array containing "null" and required' do
          let(:opts) { { required: true } }
          let(:value) { ['one', nil, 'three'] }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new(
                "#{field} cannot contain null elements"
              )
          end
        end

        context 'with type = Hash' do
          let(:opts) { { type: Hash } }
          let(:value) { [{a: 'a', b: 'b'}] }

          it 'should be strict like parent' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('unexpected params: a, b')
          end
        end

        context 'with type = Hash, unstrict child' do
          let(:opts) { { type: Hash, strict: false } }
          let(:value) { [{a: 'a'}, {b: 'b'}, {c: 'c'}] }

          it 'should allow arbitrary hash keys' do
            is_expected.to eq(field.to_sym => value)
          end
        end

        context 'with type = Hash and block' do
          let(:opts) { { type: Hash } }
          let(:block) { proc { String :a; Integer :b; Float :c } }
          let(:value) { [{a: 'a'}, {b: '2'}, {c: '3.3'}] }

          it 'should parse hash values' do
            is_expected.to eq(field.to_sym => [{a: 'a'}, {b: 2}, {c: 3.3}])
          end
        end
      end # #Array

      describe '#Hash' do
        let(:opts) { {} }
        let(:block) { nil }
        before { resource_params.Hash(field, opts, &block) }
        let(:field) { :a_hash }
        subject { resource_params.validate(field => value) }

        context 'with nil value' do
          let(:value) { nil }
          it { is_expected.to eq(field => nil) }
        end

        context 'with empty hash' do
          let(:value) { {} }
          it { is_expected.to eq(field.to_sym => value) }
        end

        context 'with String instead of Hash' do
          let(:value) { "some_string" }

          it 'should raise an error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new("expected a_hash to be of type Hash")
          end
        end

        context 'with strict parent' do
          let(:value) { { a: 'a', b: 'b', c: 'c' } }

          it 'should should be strict too' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('unexpected params: a, b, c')
          end
        end

        context 'with strict parent and unstrict child' do
          let(:opts) { { strict: false } }
          let(:value) { { a: 'a', b: 'b', c: 'c' } }

          it 'should not be strict' do
            is_expected.to eq(field.to_sym => value)
          end
        end

        context 'with unstrict parent' do
          let(:params_opts) { { strict: false } }
          let(:value) { { a: 'a', b: 'b', c: 'c' } }

          it 'should inherit lack of strictness' do
            is_expected.to eq(field.to_sym => value)
          end
        end

        context 'with unstrict parent but strict child' do
          let(:params_opts) { { strict: false } }
          let(:opts) { { strict: true } }
          let(:value) { { a: 'a', b: 'b', c: 'c' } }

          it 'should should be strict' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('unexpected params: a, b, c')
          end
        end

        context 'with block' do
          let(:block) { proc { String :a; Integer :b; Float :c } }
          let(:value) { { a: 'a', b: '2', c: '3.3' } }

          it 'should parse child params' do
            is_expected.to eq(a_hash: {a: 'a', b: 2, c: 3.3})
          end
        end

        context 'with block and extra params given' do
          let(:block) { proc { String :a } }
          let(:value) { { a: 'a', b: '2', c: '3.3' } }

          it 'should should complain about extra field' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('unexpected params: b, c')
          end
        end
      end # #Hash

      describe '#Boolean' do
        before { resource_params.Boolean(field, opts) }
        let(:field) { :a_boolean }
        subject { resource_params.validate(field => value) }

        let(:opts) { {} }

        context 'with value of "true"' do
          let(:value) { 'true' }
          it { is_expected.to eq(field.to_sym => true) }
        end

        context 'with value of "TRUE"' do
          let(:value) { 'TRUE' }
          it { is_expected.to eq(field.to_sym => true) }
        end

        context 'with value of "false"' do
          let(:value) { 'false' }
          it { is_expected.to eq(field.to_sym => false) }
        end

        context 'with value of "t"' do
          # Full word of "true" is required.
          let(:value) { 't' }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('a_boolean does not match '\
                '/\A(true|false)\z/i')
          end
        end
      end # #Boolean

      describe '#DateTime' do
        before { resource_params.DateTime(field, opts) }
        let(:field) { :a_datetime }
        subject { resource_params.validate(field => value) }

        context 'with between?(2015-10-08, 2015-10-10)' do
          let(:opts) {
            { between?: [DateTime.new(2015,10,8), DateTime.new(2015,10,10)] }
          }

          context 'with value of "2015-10-09T08:30:30-07:00"' do
            let(:value) { '2015-10-09T08:30:30-07:00' }
            it { is_expected.to eq(field.to_sym => DateTime.parse(value)) }
          end

          context 'with value of "2015-10-08"' do
            let(:value) { '2015-10-08' }
            it { is_expected.to eq(field.to_sym => DateTime.parse(value)) }
          end

          context 'with value of "08/10/2015"' do
            let(:value) { '08/10/2015' }
            it { is_expected.to eq(field.to_sym => DateTime.parse(value)) }
          end

          context 'with value of "10/08/2015"' do
            let(:value) { '10/08/2015' }

            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new(
                  "#{field} failed between?(2015-10-08T00:00:00+00:00," \
                  "2015-10-10T00:00:00+00:00) validation"
                )
            end
          end

          context 'with value of "2000-10-09T08:30:30-07:00"' do
            let(:value) { '2000-10-09T08:30:30-07:00' }
            it 'should throw validation error' do
              expect { subject }.to throw_symbol :error,
                Errors::ValidationError.new(
                  "#{field} failed between?(2015-10-08T00:00:00+00:00," \
                  "2015-10-10T00:00:00+00:00) validation"
                )
            end
          end
        end # with match(/\A\w+\z/)
      end # #DateTime

      describe '#use' do
        let(:other_params) {
          Params.new({}) {
            String  :other_string, required: true
            Integer :other_integer, required: true
            Float   :other_float,  required: true
            Symbol  :other_symbol, required: true
          }
        }
        let(:params) { Params.new({}) { Boolean :my_boolean, required: true } }
        before { params.use(other_params) }
        subject { params.validate({}) }

        it 'should merge the params' do
          error = catch(:error) { subject }
          expect(error).to eq Rester::Errors::ValidationError.new(
            'missing params: my_boolean, other_string, other_integer, other_float, other_symbol')
        end
      end # #use

      context 'with default values' do
        let(:resource_params) { Params.new(params_opts) }
        let(:params_opts) { {} }

        describe '#Integer' do
          subject { resource_params.validate(params) }
          let(:params) { {} }
          let(:field) { :an_integer }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { 5 }
            before { resource_params.Integer(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value } }

              context 'with value of "1"' do
                let(:value) { '1' }
                it { is_expected.to eq(field.to_sym => value.to_i) }
              end # with value of "1"
            end # with value
          end # with valid default

          context 'with invalid default' do
            subject { resource_params.Integer(field, opts) }

            context 'wrong type' do
              let(:default_value) { "hello" }

              it 'should raise an error' do
                expect { subject }.to raise_error(
                  Rester::Errors::ValidationError,
                  'default for an_integer should be of type Integer'
                )
              end
            end # wrong type

            context 'with other options' do
              let(:opts) { { default: default_value, between?: [1, 10] } }
              let(:default_value) { 0 }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  "an_integer failed between?(1,10) validation"
              end
            end # with other options
          end # with invalid default
        end # #Integer

        describe '#String' do
          subject { resource_params.validate(params) }
          let(:field) { :a_string }
          let(:params) { {} }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { "hello" }
            before { resource_params.String(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value } }

              context 'with value of "testing"' do
                let(:value) { 'testing' }
                it { is_expected.to eq(field.to_sym => value) }
              end # with value of "testing"
            end # with value
          end # with valid default

          context 'with invalid default' do
            subject { resource_params.String(field, opts) }

            context 'wrong type' do
              let(:default_value) { 5 }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'default for a_string should be of type String'
              end
            end # wrong type

            context 'with other options' do
              let(:opts) { { default: default_value, match: /\A\w+\z/ } }
              let(:default_value) { '!@#$' }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'a_string does not match /\A\w+\z/'
              end
            end # with other options
          end # with invalid default
        end # #String

        describe '#Symbol' do
          subject { resource_params.validate(params) }
          let(:field) { :a_symbol }
          let(:params) { {} }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { :test_symbol }
            before { resource_params.Symbol(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value.to_s } }

              context 'with value of :hello' do
                let(:value) { :hello }
                it { is_expected.to eq(field.to_sym => value) }
              end
            end # with value
          end # with valid default


          context 'with invalid default' do
            subject { resource_params.Symbol(field, opts) }

            context 'wrong type' do
              let(:default_value) { 1234 }

              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'default for a_symbol should be of type Symbol'
              end

              context 'with other options' do
                let(:opts) { { default: default_value, within: [:this, :that] } }
                let(:default_value) { :bad_default }

                it 'should raise an error' do
                  expect { subject }.to raise_error Rester::Errors::ValidationError,
                    "a_symbol not within [:this, :that]"
                end
              end # with other options
            end # wrong type

          end # with invalid default
        end # #Symbol

        describe '#Float' do
          subject { resource_params.validate(params) }
          let(:field) { :a_float }
          let(:params) { {} }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { 3.14 }
            before { resource_params.Float(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value } }

              context 'with value of 1.23' do
                let(:value) { '1.23' }
                it { is_expected.to eq(field.to_sym => value.to_f) }
              end # with value of "testing"
            end # with value
          end # with valid default

          context 'with invalid default' do
            subject { resource_params.Float(field, opts) }

            context 'wrong type' do
              let(:default_value) { 'bad_value' }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'default for a_float should be of type Float'
              end
            end # wrong type

            context 'with other options' do
              let(:opts) { { default: default_value, zero?: [] } }
              let(:default_value) { 3.14 }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  "a_float failed zero?() validation"
              end
            end # with other options
          end # with invalid default
        end # #Float

        describe '#Boolean' do
          subject { resource_params.validate(params) }
          let(:field) { :a_boolean }
          let(:params) { {} }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { true }
            before { resource_params.Boolean(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value } }

              context 'with value of 1.23' do
                let(:value) { 'false' }
                it { is_expected.to eq(field.to_sym => false) }
              end # with value of "testing"
            end # with value
          end # with valid default

          context 'with invalid default' do
            subject { resource_params.Boolean(field, opts) }

            context 'wrong type' do
              let(:default_value) { 'bad_value' }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'default for a_boolean should be of type Boolean'
              end
            end # wrong type
          end # with invalid default
        end # #Boolean

        describe '#Datetime' do
          subject { resource_params.validate(params) }
          let(:field) { :a_datetime }
          let(:params) { {} }
          let(:opts) { { default: default_value } }

          context 'with valid default' do
            let(:default_value) { DateTime.parse('2015-10-09T08:30:30-07:00') }
            before { resource_params.DateTime(field, opts) }

            context 'with no value' do
              it { is_expected.to eq(field.to_sym => default_value) }
            end # with no value

            context 'with value' do
              let(:params) { { field => value } }

              context 'with value of 1.23' do
                let(:value) { '2015-12-10T08:30:30-07:00'  }
                it { is_expected.to eq(field.to_sym => DateTime.parse(value)) }
              end # with value of "testing"
            end # with value
          end # with valid default

          context 'with invalid default' do
            subject { resource_params.DateTime(field, opts) }

            context 'wrong type' do
              let(:default_value) { 'bad_value' }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                  'default for a_datetime should be of type DateTime'
              end
            end # wrong type

            context 'with other options' do
              let(:opts) {
                {
                  default: default_value,
                  between?: [DateTime.new(2015,10,8), DateTime.new(2015,10,10)]
                }
              }
              let(:default_value) { DateTime.parse('2015-10-01T08:30:30-07:00') }
              it 'should raise an error' do
                expect { subject }.to raise_error Rester::Errors::ValidationError,
                "a_datetime failed between?(2015-10-08T00:00:00+00:00,2015-10-10T00:00:00+00:00) validation"
              end
            end # with other options
          end # with invalid default
        end # #Datetime
      end # with default values

      context 'with dynamic field names' do
        before do
          resource_params.String(/\Atest_field.+\z/)
          resource_params.Integer(/\Amy_integer.+\z/)
          resource_params.Hash(/\Amy_hash.+\z/, {}) do
            String :test_name, required: true
          end
        end

        subject { resource_params.validate(params) }

        context 'with valid key name' do
          let(:params) do
            {
              test_field_name: 'test',
              my_integer_field: '3',
              my_hash_field: { test_name: 'hello' }
            }
          end

          it 'should match the fields with the regex' do
            is_expected.to eq(
              test_field_name: 'test',
              my_integer_field: 3,
              my_hash_field: { test_name: 'hello' }
            )
          end
        end

        context 'with missing required nested value' do
          let(:params) do
            {
              test_field_name: 'test',
              my_integer_field: '3',
              my_hash_field: {}
            }
          end

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('missing params: test_name')
          end
        end

        context 'with invalid key name' do
          let(:params) { { invalid_test_field_name: 'test' } }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError
                .new('unexpected params: invalid_test_field_name')
          end
        end
      end

      context 'with required field' do
        before {
          resource_params.Integer :int, required: true
          resource_params.String :str
          resource_params.Float :float, required: true
        }

        subject { resource_params.validate(params) }

        context 'with all params' do
          let(:params) { { int: '1234', str: 'hello there', float: '3.14159' } }
          it { expect { subject }.not_to throw_symbol }
        end # with all params

        context 'with required only' do
          let(:params) { { int: '1234', float: '3.14159' } }
          it { expect { subject }.not_to throw_symbol }
        end # with required only

        context 'with no params' do
          let(:params) { {} }
          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('missing params: int, float')
          end
        end # with no params
      end # with required field

      context 'with strict validation' do
        let(:params_opts) { { strict: true } }

        before {
          resource_params.Integer(:an_integer)
          resource_params.String(:a_string)
        }

        subject { resource_params.validate(params) }

        context 'with expected params' do
          let(:params) { { an_integer: '1', a_string: 'hello' } }
          it { expect { subject }.not_to throw_symbol }
        end # with expected params

        context 'with no params' do
          let(:params) { {} }
          it { expect { subject }.not_to throw_symbol }
        end # with no params

        context 'with extra params' do
          let(:params) { { an_integer: '1', extra: 'value'} }

          it 'should throw validation error' do
            expect { subject }.to throw_symbol :error,
              Errors::ValidationError.new('unexpected params: extra')
          end
        end # with extra params
      end # with strict validation
    end # Params
  end # Service::Resource
end # Rester
