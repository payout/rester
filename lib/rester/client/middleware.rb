module Rester
  class Client
    module Middleware
      autoload(:Base,           'rester/client/middleware/base')
      autoload(:RequestHandler, 'rester/client/middleware/request_handler')
    end
  end
end
