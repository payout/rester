require 'date'

module Rester
  class Service::Resource
    RSpec.describe Validator do
      let(:validator) { Validator.new(validator_opts) }
      let(:validator_opts) { {} }

      describe '#Integer' do
        before { validator.Integer(field, opts) }
        let(:field) { :an_integer }
        subject { validator.validate(field => value) }

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
      end # #Integer

      describe '#String' do
        before { validator.String(field, opts) }
        let(:field) { :a_string }
        subject { validator.validate(field => value) }

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
                Errors::ValidationError.new(
                  "#{field} failed match((?-mix:\\A\\w+\\z)) validation"
                )
            end
          end
        end # with match(/\A\w+\z/)
      end # #String

      describe '#Symbol' do
        before { validator.Symbol(field, opts) }
        let(:field) { :a_symbol }
        subject { validator.validate(field => value) }

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
        before { validator.Float(field, opts) }
        let(:field) { :a_float }
        subject { validator.validate(field => value) }

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
      end # #Float

      describe '#Boolean' do
        before { validator.Boolean(field, opts) }
        let(:field) { :a_boolean }
        subject { validator.validate(field => value) }

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
          it { is_expected.to eq(field.to_sym => false) }
        end
      end # #Boolean

      describe '#DateTime' do
        before { validator.DateTime(field, opts) }
        let(:field) { :a_datetime }
        subject { validator.validate(field => value) }

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

      context 'with required field' do
        before {
          validator.Integer :int, required: true
          validator.String :str
          validator.Float :float, required: true
        }

        subject { validator.validate(params) }

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
        let(:validator_opts) { { strict: true } }

        before {
          validator.Integer(:an_integer)
          validator.String(:a_string)
        }

        subject { validator.validate(params) }

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
    end # Validator
  end # Service::Resource
end # Rester
