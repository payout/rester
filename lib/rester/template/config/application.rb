require File.expand_path('../boot', __FILE__)

require 'active_record'
require 'standalone_migrations'
StandaloneMigrations::Configurator.load_configurations
ActiveRecord::Base.establish_connection

# Add the lib directory to the include path.
$: << File.expand_path('../../lib', __FILE__)

# Helpers
Dir[File.expand_path('../../app/helpers/*', __FILE__)].each { |f| require f }

# Services are the root of the application. From there, individual files must be
# required as needed.
Dir[File.expand_path('../../app/services/*', __FILE__)].each { |f| require f }

require File.expand_path('../../app/models', __FILE__)