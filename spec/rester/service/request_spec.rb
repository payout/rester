module Rester
  class Service
    RSpec.describe Request do
      let(:request) { Request.new(env) }
      let(:env) { {} }

      describe '#valid?' do
        subject { request.valid? }

        let(:env) { { 'PATH_INFO' => path } }

        context 'with path=/status' do
          let(:path) { '/status' }
          it { is_expected.to be false }
        end

        context 'with path=/v1' do
          let(:path) { '/v1' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/status' do
          let(:path) { '/v1/status' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/test/id' do
          let(:path) { '/v1/test/id' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/test/123-123' do
          let(:path) { '/v1/test/123-123' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/123-12' do
          let(:path) { '/v1/123-12' }
          it { is_expected.to be false }
        end

        context 'with path=/v1/test/123-123/another' do
          let(:path) { '/v1/test/123-123/another' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/test/123-123/another-one' do
          let(:path) { '/v1/test/123-123/another-one' }
          it { is_expected.to be false }
        end

        context 'with path=/v1/test/123-123/another/123-12' do
          let(:path) { '/v1/test/123-123/another/123-12' }
          it { is_expected.to be true }
        end

        context 'with path=/v1/test/id/another/another_id' do
          let(:path) { '/v1/test/id/another/another_id' }
          it { is_expected.to be true }
        end
      end
    end
  end
end
