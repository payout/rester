require 'date'

module Rester
  class Service
    RSpec.describe Resource do
      let(:object) { Class.new(Resource) }

      describe '::params' do
        subject {
          object.params strict: true, an_option: 'value' do
            Integer  :one, between?: [1, 10], required: true
            String   :two, match: /hello world/, required: true
            Symbol   :three, within: [:a, :b, :c], required: false
            Float    :four
            DateTime :five
          end
        }

        it 'should have set options' do
          expect(subject.options).to eq(strict: true, an_option: 'value')
          expect(subject.strict?).to be true
        end
      end # ::params


      describe '#method_params' do
        subject { object.method_params }

        it { is_expected.to eq({}) }

        context 'with method params set' do
          let(:search_params) {
            object.params do
              Integer :one
            end
          }
          let(:create_params) {
            object.params do
              String :one
            end
          }
          before {
            search_params
            object.method_added(:search)
            create_params
            object.method_added(:create)
          }

          it {
            is_expected.to include(
              search: search_params,
              create: create_params
            )
          }
        end # with method params set
      end # #method_params


      describe '#method_added' do
        let(:method_name) { '' }
        let(:params) {}
        before {
          params
          object.method_added(method_name)
        }
        subject { object.method_params }

        context 'with valid method_name' do
          context 'with default Params.new' do
            context 'search' do
              let(:method_name) { 'search' }

              it {
                is_expected.to include(
                  search: Resource::Params,
                )
              }
            end # search

            context 'create' do
              let(:method_name) { 'create' }

              it {
                is_expected.to include(
                  create: Resource::Params
                )
              }
            end # create

            context 'get' do
              let(:method_name) { 'get' }

              it {
                is_expected.to include(
                  get: Resource::Params
                )
              }
            end # get

            context 'update' do
              let(:method_name) { 'update' }

              it {
                is_expected.to include(
                  update: Resource::Params
                )
              }
            end # update

            context 'delete' do
              let(:method_name) { 'delete' }

              it {
                is_expected.to include(
                  delete: Resource::Params
                )
              }
            end # delete
          end # with default Params.new

          context 'with params set' do
            let(:params) {
              object.params do
                String :one
              end
            }

            context 'create' do
              let(:method_name) { 'create' }

              it {
                is_expected.to include(
                  create: params
                )
              }
            end # create
          end # with params set
        end # with valid method_name

        context 'with multiple methods added' do
          let(:search_params) {
            object.params do
              String :one
            end
          }
          let(:create_params) {
            object.params do
              Integer :one
            end
          }
          let(:get_params) {
            object.params do
              Symbol :one
            end
          }
          let(:update_params) {
            object.params do
              Float :one
            end
          }
          let(:delete_params) {
            object.params do
              Boolean :one
            end
          }
          before {
            search_params
            object.method_added(:search)
            create_params
            object.method_added(:create)
            get_params
            object.method_added(:get)
            update_params
            object.method_added(:update)
            delete_params
            object.method_added(:delete)
          }

          it {
            is_expected.to include(
              search: search_params,
              create: create_params,
              get: get_params,
              update: update_params,
              delete: delete_params
            )
          }
        end # with multiple methods added

        context 'with invalid method_name' do
          context 'delete' do
            let(:method_name) { 'bad_method_name' }

            it { is_expected.to eq({}) }
          end # delete
        end # with invalid method_name
      end # #method_added

      describe '#method_params_for' do
        let(:search_params) {
          object.params do
            String :one
          end
        }
        before {
          search_params
          object.method_added(:search)
        }

        subject { object.new.method_params_for(method_name) }
        let(:method_name) { 'search' }

        it { is_expected.to eq search_params }

        context 'with method having no params' do
          let(:method_name) { 'get' }
          it { is_expected.to eq nil }
        end # with method having no params
      end # #method_params_for

      describe '#process' do
        let(:resource) { Rester::DummyService::V1::TestWithNonHashValue.new }
        let(:params) { {} }
        subject { resource.process('GET', nil, params) }

        it { is_expected.to eq(this: :that) }

        context 'with nil retval' do
          let(:params) { { "nil_return_val" => "true" } }
          it { is_expected.to eq({}) }
        end

        describe 'per-method params' do
          let(:resource) { Rester::DummyService::V1::TestWithParams.new }
          let(:request_method) { '' }
          let(:id_provided) { nil }

          subject { resource.process(request_method, id_provided) }

          context 'search' do
            let(:request_method) { 'GET' }
            it { is_expected.to eq my_string: "string" }
          end # search

          context 'create' do
            let(:request_method) { 'POST' }
            it { is_expected.to eq my_integer: 1 }
          end # create

          context 'get' do
            let(:request_method) { 'GET' }
            let(:id_provided) { 'some_id' }
            it { is_expected.to eq my_symbol: :symbol }
          end # get

          context 'update' do
            let(:request_method) { 'PUT' }
            let(:id_provided) { 'some_id' }
            it { is_expected.to eq my_float: 1.23 }
          end # update

          context 'delete' do
            let(:request_method) { 'DELETE' }
            let(:id_provided) { 'some_id' }
            it { is_expected.to eq my_boolean: true }
          end # delete
        end # per-method params
      end # #process

      describe '#error!' do
        let(:message) { nil }
        let(:resource) { Rester::DummyService::V1::Test.new }
        subject {
          catch(:error) do
            resource.error!(message)
          end
        }

        it 'should raise an error' do
          expect(subject).to be_a Rester::Errors::RequestError
        end

        context 'with message' do
          let(:message) { "Error Message" }

          it 'should raise an error' do
            expect(subject).to eq Rester::Errors::RequestError.new(message)
          end
        end # with message
      end # #error!
    end # Resource
  end # Service
end # Rester
