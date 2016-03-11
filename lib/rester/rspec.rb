require 'json'

##
# include_stub_response custom matcher which checks inclusion on nested arrays
# and objects as opposed to the top level object which RSpec's include only
# checks
RSpec::Matchers.define :include_stub_response do |stub|
  failure = nil

  match { |actual|
    begin
      # If a stub is passed in by the user, check both the stub file and the
      # response for inclusion. This is helpful for cases when a field is better
      # tested with a Regex in the Producer-side testing: ie :created_at in POST
      Rester::Utils::RSpec.assert_deep_include(stub_response, stub) if stub
      expected = stub ? stub_response.merge(stub) : stub_response

      Rester::Utils::RSpec.assert_deep_include(actual, expected)
    rescue Rester::Errors::StubError => e
      failure = e
      false
    end
  }

  failure_message { failure }
end

RSpec.configure do |config|
  config.before :all, rester: // do |ex|
    # Load the stub file
    @rester_stub_filepath = ex.class.metadata[:rester]
    @rester_stub = Rester::Utils::StubFile.new(@rester_stub_filepath)

    # Hook up the LocalAdapter with the Service being tested
    unless (klass = ex.class.described_class) < Rester::Service
      raise "invalid service to test"
    end

    @rester_adapter = Rester::Client::Adapters::LocalAdapter.new(klass)

    _validate_test_coverage(ex)
  end

  config.before :each, rester: // do |ex|
    _setup_example(ex) unless ex.pending?
  end

  config.after :each, rester: // do
    if defined?(service_response_code)
      expect(service_response_code).to eq stub_response_code
    end
  end

  def _setup_example(ex)
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
    # context, verb, path = ['With some context', 'GET', '/v1/tests']
    context, verb, path = ex.example_group.parent_groups.map { |a|
      a.description unless a.metadata[:description] == a.described_class.to_s
    }.compact

    begin
      spec = @rester_stub[path][verb][context]
      _stub_path_not_found(path, verb, context) unless spec
    rescue NoMethodError
      _stub_path_not_found(path, verb, context)
    end

    ##
    # Raw response from the service.
    # [HTTP CODE, JSON String]
    ex.example_group.let(:raw_service_response) {
      @rester_adapter.request(verb.downcase.to_sym, path, spec['request'])
    }

    ##
    # Parsed service response
    ex.example_group.let(:service_response) {
      JSON.parse(raw_service_response.last, symbolize_names: true)
    }

    ##
    # HTTP status code returned by service.
    ex.example_group.let(:service_response_code) { raw_service_response.first }

    ##
    # Expected response body specified in by the stub.
    ex.example_group.let(:stub_response) {
      JSON.parse((spec['response'] || {}).to_json, symbolize_names: true)
    }

    ##
    # HTTP status code expected by the stub.
    ex.example_group.let(:stub_response_code) { spec['response_code'] }

    ##
    # Set the subject to be the service response (parsed ruby hash of the
    # returned data).
    ex.example_group.let(:subject) { service_response }
  end

  def _stub_path_not_found(path, verb, context)
    fail Rester::Errors::TestError,
      "Could not find path: #{path.inspect} verb: #{verb.inspect} context: "\
        "#{context.inspect} in #{@rester_stub_filepath}"
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
          _find_or_create_child(verb_group, missing_context).pending
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
    Hash[@rester_stub.reject { |k, _|
      ['version', 'consumer', 'producer'].include?(k)
    }.map { |path, verbs|
      [
        path,
        Hash[verbs.map { |verb, contexts|
          [
            verb,
            Hash[contexts.map { |context, _|
              [
                context,
                !!(tests[path] && tests[path][verb] && tests[path][verb][context])
              ]
            }].reject { |_, v| v }
          ]
        }].reject { |_, v| v.empty? }
      ]
    }].reject { |_, v| v.empty? }
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
