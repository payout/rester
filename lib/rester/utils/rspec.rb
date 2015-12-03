module Rester
  module Utils
    module RSpec
      class << self
        def deep_include?(subject, stub, accessors=[])
          case stub
          when Hash
            _match_error(subject, stub, accessors) unless subject.is_a?(Hash)

            stub.all? { |k,v|
              case v
              when Array
                unless subject[k].is_a?(Array)
                  _match_error(subject[k], v, accessors + [k])
                end

                v.each_with_index.all? { |e,i|
                  deep_include?(subject[k][i], e, accessors + [k, i])
                }
              else
                deep_include?(subject[k], v, accessors + [k])
              end
            }
          when Array
            _match_error(subject, stub, accessors) unless subject[k].is_a?(Array)

            stub.each_with_index.all? { |e,i|
              deep_include?(subject[i], e, accessors + [i])
            }
          else
            _match_error(subject, stub, accessors) unless stub == subject
            true
          end
        end

        def _match_error(subject, stub, accessors=[])
          accessors_str = _pretty_print_accessors(accessors)
          fail Errors::StubError, "Stub#{accessors_str}=#{stub.inspect} doesn't match Response#{accessors_str}=#{subject.inspect}"
        end

        def _pretty_print_accessors(accessors=[])
          accessors.map { |a| "[#{a.inspect}]" }.join
        end
      end # Class Methods
    end # RSpec
  end # Utils
end # Rester
