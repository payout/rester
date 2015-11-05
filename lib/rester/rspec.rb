require 'json'

RSpec.configure do |config|
  config.before :all, rester: // do |ex|
    # Load the stub file
    @rester_stub_filepath = ex.class.metadata[:rester]
    @rester_stub = YAML.load_file(@rester_stub_filepath)

    # Hook up the LocalAdapter with the Service being tested
    unless (klass = ex.class.described_class) < Rester::Service
      raise "invalid service to test"
    end
    @rester_adapter = Rester::Client::Adapters::LocalAdapter.new(klass, {})

    _validate_test_coverage(ex)
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
      params   = @rester_stub[path][verb][context]['request']
      response = @rester_stub[path][verb][context]['response']
    rescue NoMethodError
      fail Rester::Errors::StubError,
        "Could not find path: #{path.inspect} verb: #{verb.inspect} context: #{context.inspect} in #{@rester_stub_filepath}"
    end

    ex.example_group.let(:subject) {
      @rester_adapter.request(verb.downcase.to_sym, path, params)
    }

    ex.example_group.let(:stub_response) {
      [response['code'], response['body'].to_json]
    }
  end

  config.after :each, rester: // do |ex|
    expect(subject).to eq stub_response
  end

  ##
  # Check to see if each stub example has a corresponding test written for it
  def _validate_test_coverage(ex)
    rester_service_tests = _rester_service_tests(ex)
    missing_tests = _missing_stub_tests(rester_service_tests)

    # Loop through each missing stub test and create a corresponding RSpect test
    # to display the missing tests as a failure to the user
    missing_tests.each { |missing_path, missing_verbs|
      path_group = _find_or_create_child(ex.class, missing_path)

      missing_verbs.each { |missing_verb, missing_contexts|
        verb_group = _find_or_create_child(path_group, missing_verb)

        missing_contexts.each { |missing_context, _|
          context_group = _find_or_create_child(verb_group, missing_context)
          context_group.it { is_expected.to eq stub_response }
        }
      }
    }
  end

  def _rester_service_tests(parent_example_group)
    service_tests = {}
    parent_example_group.class.children.each { |path_group|
      path = path_group.description
      service_tests[path] ||= {}

      path_group.children.each { |verb_group|
        verb = verb_group.description
        service_tests[path][verb] ||= {}

        verb_group.children.each { |context_group|
          context =  context_group.description
          service_tests[path][verb][context] = context_group.examples.count > 0
        }
      }
    }

    service_tests
  end

  ##
  # Takes a hash produced by _rester_service_tests.
  # Returns a hash of only the missing stub tests:
  #
  # {
  #   "/v1/tests/abc123/mounted_objects" => {
  #     "POST" => {
  #       "With some context" => false
  #     }
  #   },
  #   "/v1/stuff" => {
  #     "GET" => {
  #       "Doing that" => false
  #     }
  #   }
  # }
  def _missing_stub_tests(tests)
    @rester_stub.reject { |k, _|
      ['version', 'consumer', 'producer'].include?(k)
    }.map { |path, verbs|
      [
        path,
        verbs.map { |verb, contexts|
          [
            verb,
            contexts.map { |context, _|
              [
                context,
                !!(tests[path] && tests[path][verb] && tests[path][verb][context])
              ]
            }.to_h.reject { |_, v| v }
          ]
        }.to_h.reject { |_, v| v.empty? }
      ]
    }.to_h.reject { |_, v| v.empty? }
  end

  def _find_child_with_description(group, description)
    group.children.find { |child_group|
      child_group.description == description
    }
  end

  def _find_or_create_child(group, description)
    child = _find_child_with_description(group, description)
    child || group.describe(description)
  end
end
