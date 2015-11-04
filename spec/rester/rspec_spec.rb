require 'rester/rspec'

RSpec.describe Rester::DummyService, rester: 'spec/stubs/dummy_service_stub.yml' do
  describe '/v1/tests' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # GET

    context 'POST' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # POST
  end # /v1/tests

  describe '/v1/tests/abc123' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # GET

    context 'PUT' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # PUT

    context 'DELETE' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # DELETE
  end # /v1/tests/abc123

  describe '/v1/tests/abc123/mounted_objects' do
    context 'GET' do
      context 'With some context' do
        it { is_expected.to eq stub_response }
      end
    end # GET
  end # /v1/tests/abc123/mounted_objects
end # DummyService
