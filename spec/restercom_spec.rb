RSpec.describe Restercom do
  describe '::connect' do
    let(:url) { RSpec.server_uri }
    subject { Restercom.connect(url) }
    it { is_expected.to be_a Restercom::Client }
  end # ::connect
end # Restercom
