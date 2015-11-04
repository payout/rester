RSpec.describe Rester do
  describe '::connect' do
RSpec.configure { |c|
  c.before :each, rester: // do |ex|
    ex.example_group.let(:subject) { 'blah' }
    puts "I'm Running! #{self.class.metadata}"
  end
}

RSpec.describe Rester, rester: 'asdf' do
  it '', :test do
    puts subject.inspect
  end

  describe '/path/to/this' do
    subject { Rester.connect(*connect_args) }

    context 'with url' do
    context 'POST' do
      let(:url) { RSpec.server_uri }
      let(:connect_args) { [url] }

      it { is_expected.to be_a Rester::Client }

      context 'With something done' do
        it 'blah afuck hyou' do
          string = ""
          raise self.class.metadata.inspect

          # self.class.ancestors.each { |a|
          #   string << a.description + " " if a < RSpec::Core::ExampleGroup
          # }
          # raise string.inspect
          # raise self.__memoized.inspect
          # raise self.instance_variable_names.inspect
          # raise self.to_json.inspect
          # raise self.methods.sort.inspect
        end
      end
