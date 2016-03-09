module Rester
  module Utils
    module RSpec
      class << self
        def assert_deep_include(response, stub, accessors=[])
          case stub
          when Hash
            _type_error(response, stub, accessors) unless response.is_a?(Hash)
            stub.all? { |k,v| assert_deep_include(response[k], v, accessors + [k]) }
          when Array
            unless response.is_a?(Array)
              _type_error(response, stub, accessors)
            end

            unless response.length == stub.length
              _length_error(response, stub, accessors)
            end

            stub.each_with_index.all? { |e,i|
              assert_deep_include(response[i], e, accessors + [i])
            }
          else
            unless stub == response || (stub.is_a?(Regexp) && stub =~ response)
              _match_error(response, stub, accessors)
            end
            true
          end
        end

        def _match_error(response, stub, accessors=[])
          accessors_str = _pretty_print_accessors(accessors)
          fail Errors::StubError, "Stub#{accessors_str}=#{stub.inspect} doesn't match Response#{accessors_str}=#{response.inspect}"
        end

        def _length_error(response, stub, accessors=[])
          accessors_str = _pretty_print_accessors(accessors)
          fail Errors::StubError, "Stub#{accessors_str} length: #{stub.length} doesn't match Response#{accessors_str} length: #{response.length}"
        end

        def _type_error(response, stub, accessors=[])
          accessors_str = _pretty_print_accessors(accessors)
          fail Errors::StubError, "Stub#{accessors_str} type: #{stub.class} doesn't match Response#{accessors_str} type: #{response.class}"
        end

        def _pretty_print_accessors(accessors=[])
          accessors.map { |a| "[#{a.inspect}]" }.join
        end
      end # Class Methods
    end # RSpec
  end # Utils
end # Rester
