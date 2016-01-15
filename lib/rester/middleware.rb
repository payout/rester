module Rester
  module Middleware
    autoload(:Base,          'rester/middleware/base')
    autoload(:ErrorHandling, 'rester/middleware/error_handling')
    autoload(:Ping,          'rester/middleware/ping')
    autoload(:NewRelic,      'rester/middleware/new_relic')
    autoload(:CorrelationId, 'rester/middleware/correlation_id')
    autoload(:Identify,      'rester/middleware/identify')
  end
end
