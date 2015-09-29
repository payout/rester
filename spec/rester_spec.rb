RSpec.describe Rester do
  describe '::connect' do
    let(:url) { RSpec.server_uri }
    subject { Rester.connect(url) }
    it { is_expected.to be_a Rester::Client }
  end # ::connect
end # Rester
