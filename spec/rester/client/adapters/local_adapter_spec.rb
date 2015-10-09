module Rester
  module Client::Adapters
    RSpec.describe LocalAdapter do
      let(:adapter) { LocalAdapter.new(DummyService) }

      describe '#get!' do
        let(:params) { {} }
        subject { adapter.get!(path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last.body.first }

        context 'with path "/v1/tests/token"' do
          let(:path) { '/v1/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"token":"token","params":{},"method":"get"}'
          end
        end

        context 'with path "/v1/tests"' do
          let(:path) { '/v1/tests' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"search"}'
          end
        end

        context 'with path "/v1/tests/1234/mounted_objects"' do
          let(:path) { '/v1/tests/1234/mounted_objects' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"test_token":"1234","method":"search"}'
          end
        end
      end # #get!

      describe '#delete!' do
        let(:params) { {} }
        subject { adapter.delete!(path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last.body.first }

        context 'with path "/v1/tests/token"' do
          let(:path) { '/v1/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"token":"token","params":{},"method":"delete"}'
          end
        end

        context 'with path "/v1/tests"' do
          let(:path) { '/v1/tests' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/v1/tests/1234/mounted_objects"' do
          let(:path) { '/v1/tests/1234/mounted_objects' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end
      end # #delete!

      describe '#post!' do
        let(:params) { {} }
        subject { adapter.post!(path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last.body.first }

        context 'with path "/v1/tests/token"' do
          let(:path) { '/v1/tests/token' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/v1/tests"' do
          let(:path) { '/v1/tests' }

          it 'should return 201 status' do
            expect(status).to eq 201
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"create"}'
          end
        end

        context 'with path "/v1/tests/1234/mounted_objects"' do
          let(:path) { '/v1/tests/1234/mounted_objects' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end
      end # #post!

      describe '#put!' do
        let(:params) { {} }
        subject { adapter.put!(path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last.body.first }

        context 'with path "/v1/tests/token"' do
          let(:path) { '/v1/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"update","int":1,"float":1.1,' \
              '"bool":true,"null":null,"params":{}}'
          end
        end

        context 'with path "/v1/tests"' do
          let(:path) { '/v1/tests' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/v1/tests/1234/mounted_objects"' do
          let(:path) { '/v1/tests/1234/mounted_objects' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end
      end # #put!
    end # LocalAdapter
  end # Client::Adapters
end # Rester
