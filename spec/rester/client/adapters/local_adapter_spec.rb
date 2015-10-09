module Rester
  module Client::Adapters
    RSpec.describe LocalAdapter do
      let(:adapter) { LocalAdapter.new(DummyService, opts) }
      let(:opts) { {} }

      describe '#get!' do
        let(:params) { {} }
        subject { adapter.get!(path, params) }
        let(:status) { subject.first }
        let(:body) { subject.last }

        context 'with path "/tests/token"' do
          let(:path) { '/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"token":"token","params":{},"method":"get"}'
          end
        end

        context 'with path "/tests"' do
          let(:path) { '/tests' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"search"}'
          end

          context 'with invalid version' do
            let(:opts) { { version: 1234 } }

            it 'should return 404 status' do
              expect(status).to eq 404
            end
          end
        end

        context 'with path "/tests/1234/mounted_objects"' do
          let(:path) { '/tests/1234/mounted_objects' }

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
        let(:body) { subject.last }

        context 'with path "/tests/token"' do
          let(:path) { '/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"token":"token","params":{},"method":"delete"}'
          end
        end

        context 'with path "/tests"' do
          let(:path) { '/tests' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/tests/1234/mounted_objects"' do
          let(:path) { '/tests/1234/mounted_objects' }

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
        let(:body) { subject.last }

        context 'with path "/tests/token"' do
          let(:path) { '/tests/token' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/tests"' do
          let(:path) { '/tests' }

          it 'should return 201 status' do
            expect(status).to eq 201
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"create"}'
          end
        end

        context 'with path "/tests/1234/mounted_objects"' do
          let(:path) { '/tests/1234/mounted_objects' }

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
        let(:body) { subject.last }

        context 'with path "/tests/token"' do
          let(:path) { '/tests/token' }

          it 'should return 200 status' do
            expect(status).to eq 200
          end

          it 'should return JSON body' do
            expect(body).to eq '{"method":"update","int":1,"float":1.1,' \
              '"bool":true,"null":null,"params":{}}'
          end
        end

        context 'with path "/tests"' do
          let(:path) { '/tests' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end

        context 'with path "/tests/1234/mounted_objects"' do
          let(:path) { '/tests/1234/mounted_objects' }

          it 'should return 404 status' do
            expect(status).to eq 404
          end

          it 'should return JSON body' do
            expect(body).to be nil
          end
        end
      end # #put!

      describe '#version' do
        subject { adapter.version }
        let(:opts) { { version: 3 } }
        it { is_expected.to eq 3 }
      end # #version
    end # LocalAdapter
  end # Client::Adapters
end # Rester
