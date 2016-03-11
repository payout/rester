require 'rester/rspec'

RSpec.describe Rester::DummyService, rester: 'spec/stubs/dummy_service_stub.yml' do
  describe '/v1/tests' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :string => "some_string",
            :integer => 1,
            :float => 1.23,
            :symbol => "some_symbol",
            :bool => true,
            :method => "search"
          )
        }
      end

      context 'With fewer fields in response' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :string => "some_string",
            :method => "search"
          )
        }
      end

      context 'With no fields in response' do
        it { is_expected.to include stub_response }
        it { is_expected.to include({}) }
      end

      context 'With bad param' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :message => "integer failed between?(0,100) validation",
            :error => "validation"
          )
        }
      end

      context 'With list returned' do
        it { is_expected.to include_stub_response }
        it {
          is_expected.to include_stub_response(
            {
              some_key: 'some_value',
              some_array: [
                {
                  some_hash: {
                    a: 'a',
                    b: 'b',
                    c: 3
                  }
                },
                10
              ],
              another_hash: {
                this: 'that'
              }
            }
          )
        }
      end
    end # GET

    context 'POST' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :string => "some_string",
            :integer => 1,
            :float => 1.23,
            :symbol => "some_symbol",
            :bool => true,
            :method => "create"
          )
        }
      end

      context 'With generated token' do
        it { expect(stub_response).to include_stub_response(token: /\AAT[A-Za-z0-9]+\z/) }
      end
    end # POST
  end # /v1/tests

  describe '/v1/tests/abc123' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :token => "abc123",
            :params => {
              :string => "some_string",
              :integer => 1,
              :float => 1.23,
              :symbol => "some_symbol",
              :bool => true
            },
            :method => "get"
          )
        }
      end
    end # GET

    context 'PUT' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :method => "update",
            :int => 1,
            :float => 1.1,
            :bool => true,
            :null => nil,
            :params => {
              :string => "some_string",
              :integer => 1,
              :float => 1.23,
              :symbol => "some_symbol",
              :bool => true,
              :test_token => "abc123"
            }
          )
        }
      end
    end # PUT

    context 'DELETE' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :token => "abc123",
            :params => {
              :string => "some_string",
              :integer => 1,
              :float => 1.23,
              :symbol => "some_symbol",
              :bool => true
            },
            :method => "delete"
          )
        }
      end
    end # DELETE
  end # /v1/tests/abc123

  describe '/v1/tests/abc123/mounted_objects' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to include stub_response }
        it {
          is_expected.to include(
            :some_param => "some_param",
            :test_token => "abc123",
            :method => "search"
          )
        }
      end
    end # GET
  end # /v1/tests/abc123/mounted_objects
end # DummyService
