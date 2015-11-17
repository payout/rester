module Rester
  module StubUtils
    class << self
      def determine_status_code(verb, is_successful)
        return 400 unless is_successful
        is_successful ? verb.upcase == 'POST' ? 201 : 200 : 400
      end

      def parse_response_options(response_key)
        data = response_key.match(/\Aresponse(\[(\w+)=(\w+)(,(\w+)=(\w+))*\])?\z/)
        return {} if data[0] == 'response'
        data.to_a.compact.reject { |d| d.include?('=') }.each_slice(2).to_h
      end
    end # Class methods
  end # StubUtils
end # Rester