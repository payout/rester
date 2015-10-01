module Rester
  module Middleware
    autoload(:Base,          'rester/middleware/base')
    autoload(:ErrorHandling, 'rester/middleware/error_handling')
    autoload(:StatusCheck,   'rester/middleware/status_check')
  end
end
