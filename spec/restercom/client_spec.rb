module Restercom
  RSpec.describe Client do
    let(:client) { Client.new }
    let(:test_url) { RSpec.server_uri }

    describe '#connect', :connect do
      subject { client.connect(url) }

      context 'with valid url' do
        let(:url) { test_url }

        it 'should return nil' do
          expect(subject).to be nil
        end
      end # valid url
    end # #connect

    describe '#connected?', :connected? do
      subject { client.connected? }

      context 'before connecting' do
        it { is_expected.to be false }
      end

      context 'after connecting' do
        before { client.connect(test_url) }
        it { is_expected.to be true }
      end
    end # #connect?

    describe '#echo', :echo do
      before { client.connect(test_url) }
      subject { client.echo(*args, params) }

      let(:params) { { string: "string", integer: 1, float: 1.1, symbol: :symbol } }
      let(:args) { ['string', 2, 3.3, :symbol] }
      let(:params_after) { params.map { |k, v| [k, v.to_s] }.to_h }
      let(:args_after) { args.map(&:to_s) }

      context 'without any arguments or params' do
        it {
          expect(client.echo).to eq(
            args: [],
            params: {}
          )
        }
      end # without any arguments or params

      context 'with args but no params' do
        it {
          expect(client.echo(*args)).to eq(
            args: args_after,
            params: {}
          )
        }
      end # with args but no params

      context 'with params but no arguments' do
        it {
          expect(client.echo(params)).to eq(
            args: [],
            params: params_after
          )
        }
      end # with params but no arguments

      context 'with both params and arguments' do
        it {
          expect(client.echo(*args, params)).to eq(
            args: args_after,
            params: params_after
          )
        }
      end # with both params and arguments
    end # #echo

    describe '#echo!', :echo! do
      before { client.connect(test_url) }
      subject { client.echo!(*args, params) }

      let(:params) { { string: "string", integer: 1, float: 1.1, symbol: :symbol } }
      let(:args) { ['string', 2, 3.3, :symbol] }
      let(:params_after) { params.map { |k, v| [k, v.to_s] }.to_h }
      let(:args_after) { args.map(&:to_s) }

      context 'without any arguments or params' do
        it {
          expect(client.echo!).to eq(
            args: [],
            params: {}
          )
        }
      end # without any arguments or params

      context 'with args but no params' do
        it {
          expect(client.echo!(*args)).to eq(
            args: args_after,
            params: {}
          )
        }
      end # with args but no params

      context 'with params but no arguments' do
        it {
          expect(client.echo!(params)).to eq(
            args: [],
            params: params_after
          )
        }
      end # with params but no arguments

      context 'with both params and arguments' do
        it {
          expect(client.echo!(*args, params)).to eq(
            args: args_after,
            params: params_after
          )
        }
      end # with both params and arguments
    end # #echo!
  end # Client
end # Restercom
