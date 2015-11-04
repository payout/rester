require 'json'

RSpec.configure do |config|
  config.before :all, rester: // do |ex|
    # Load the stub file
    @stub_filepath = ex.class.metadata[:rester]
    @stub = YAML.load_file(@stub_filepath)

    # Hook up the LocalAdapter with the Service being tested
    unless (klass = ex.class.described_class) < Rester::Service
      raise "invalid service to test"
    end
    @adapter = Rester::Client::Adapters::LocalAdapter.new(klass, {})
  end

  config.before :each, rester: // do |ex|
    # Gather the request args from the spec descriptions
    #
    # For example:
    #
    # describe '/v1/tests' do
    #   context 'GET' do
    #     context 'With some context' do
    #     end
    #   end
    # end
    #
    # would produce:
    #
    # request_args = ['With some context', 'GET', '/v1/tests']
    #
    request_args = ex.example_group.parent_groups.map { |a|
      a.description unless a.metadata[:description] == a.described_class.to_s
    }.compact

    context = request_args[0]
    verb    = request_args[1]
    path    = request_args[2]

    begin
      params   = @stub[path][verb][context]['request']
      response = @stub[path][verb][context]['response']
    rescue NoMethodError => e
      raise Rester::Errors::StubError,
        "Could not find path: #{path.inspect} verb: #{verb.inspect} context: #{context.inspect} in #{@stub_filepath}"
    end


    ex.example_group.let(:subject) {
      @adapter.request(verb.downcase.to_sym, path, params)
    }

    ex.example_group.let(:stub_response) {
      [response['code'], response['body'].to_json]
    }
  end
end
