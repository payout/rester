require 'support/new_relic_test_service'

module Rester
  module Service::Middleware
    RSpec.describe NewRelic do
      let(:instance) { NewRelic.new(app) }
      let(:app) { NewRelicTestService.new }

      describe '#identify_method' do
        subject { instance.identify_method(request) }
        let(:request) { Service::Request.new(env) }
        let(:env) { { 'REQUEST_METHOD' => verb, 'PATH_INFO' => path } }

        context 'with GET /v1/tests' do
          let(:verb) { 'GET' }
          let(:path) { '/v1/tests' }
          it { is_expected.to eq 'NewRelicTestService::V1::Test/search' }
        end

        context 'with POST /v1/tests' do
          let(:verb) { 'POST' }
          let(:path) { '/v1/tests' }
          it { is_expected.to eq 'NewRelicTestService::V1::Test/create' }
        end

        context 'with GET /v1/tests/1234' do
          let(:verb) { 'GET' }
          let(:path) { '/v1/tests/1234' }
          it { is_expected.to eq 'NewRelicTestService::V1::Test/get' }
        end

        context 'with PUT /v1/tests/1234' do
          let(:verb) { 'PUT' }
          let(:path) { '/v1/tests/1234' }
          it { is_expected.to eq 'NewRelicTestService::V1::Test/update' }
        end

        context 'with DELETE /v1/tests/1234' do
          let(:verb) { 'DELETE' }
          let(:path) { '/v1/tests/1234' }
          it { is_expected.to eq 'NewRelicTestService::V1::Test/delete' }
        end

        context 'with GET /v1/tests/1234/mounted_resources' do
          let(:verb) { 'GET' }
          let(:path) { '/v1/tests/1234/mounted_resources' }
          it { is_expected.to eq 'NewRelicTestService::V1::MountedResource/'\
            'search' }
        end

        context 'with POST /v1/tests/1234/mounted_resources' do
          let(:verb) { 'POST' }
          let(:path) { '/v1/tests/1234/mounted_resources' }
          it { is_expected.to eq 'NewRelicTestService::V1::MountedResource/'\
            'create' }
        end

        context 'with GET /v1/tests/1234/mounted_resources/abcdefg' do
          let(:verb) { 'GET' }
          let(:path) { '/v1/tests/1234/mounted_resources/abcdefg' }
          it { is_expected.to eq 'NewRelicTestService::V1::MountedResource/'\
            'get' }
        end

        context 'with PUT /v1/tests/1234/mounted_resources/abcdefg' do
          let(:verb) { 'PUT' }
          let(:path) { '/v1/tests/1234/mounted_resources/abcdefg' }
          it { is_expected.to eq 'NewRelicTestService::V1::MountedResource/'\
            'update' }
        end

        context 'with DELETE /v1/tests/1234/mounted_resources/abcdefg' do
          let(:verb) { 'DELETE' }
          let(:path) { '/v1/tests/1234/mounted_resources/abcdefg' }
          it { is_expected.to eq 'NewRelicTestService::V1::MountedResource/'\
            'delete' }
        end
      end # #identify_method
    end # NewRelic
  end # Service::Middleware
end # Rester
