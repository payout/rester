module Rester
  module Middleware
    autoload(:Base,           'rester/middleware/base')
    autoload(:ErrorHandling,  'rester/middleware/error_handling')
    autoload(:Ping,           'rester/middleware/ping')
    autoload(:NewRelic,       'rester/middleware/new_relic')
    autoload(:RequestHandler, 'rester/middleware/request_handler')
  end
end
