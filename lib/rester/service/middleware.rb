module Rester
  class Service
    module Middleware
      autoload(:Base,           'rester/service/middleware/base')
      autoload(:ErrorHandling,  'rester/service/middleware/error_handling')
      autoload(:Ping,           'rester/service/middleware/ping')
      autoload(:NewRelic,       'rester/service/middleware/new_relic')
      autoload(:RequestHandler, 'rester/service/middleware/request_handler')
    end
  end
end
